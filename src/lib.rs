use std::sync::{Mutex, OnceLock};

use steel::{
    declare_module,
    steel_vm::ffi::{FFIModule, RegisterFFIFn},
};
use zbus::blocking::{Connection, Proxy};

const FCITX_DESTINATION: &str = "org.fcitx.Fcitx5";
const FCITX_PATH: &str = "/controller";
const FCITX_INTERFACE: &str = "org.fcitx.Fcitx.Controller1";
const ACTIVE_STATE: i32 = 2;

#[derive(Default)]
struct SavedState {
    active: bool,
    input_method: Option<String>,
}

static SAVED_STATE: OnceLock<Mutex<SavedState>> = OnceLock::new();

declare_module!(create_module);

fn create_module() -> FFIModule {
    let mut module = FFIModule::new("helix/fcitx-focus");

    module
        .register_fn("fcitx-save", fcitx_save)
        .register_fn("fcitx-close", fcitx_close)
        .register_fn("fcitx-save-and-close", fcitx_save_and_close)
        .register_fn("fcitx-restore", fcitx_restore);

    module
}

fn fcitx_save() {
    let _ = with_fcitx_proxy(|proxy| {
        let state = call_state(proxy).unwrap_or_default();
        let input_method = call_current_input_method(proxy).ok();
        let saved_state = SAVED_STATE.get_or_init(|| Mutex::new(SavedState::default()));

        if let Ok(mut saved_state) = saved_state.lock() {
            saved_state.active = state == ACTIVE_STATE;
            saved_state.input_method = input_method.filter(|name| !name.is_empty());
        }
    });
}

fn fcitx_close() {
    let _ = with_fcitx_proxy(|proxy| {
        let _ = proxy.call_method("Deactivate", &());
    });
}

fn fcitx_save_and_close() {
    fcitx_save();
    fcitx_close();
}

fn fcitx_restore() {
    let saved_state = SAVED_STATE.get_or_init(|| Mutex::new(SavedState::default()));
    let Ok(saved_state) = saved_state.lock() else {
        return;
    };

    if !saved_state.active {
        return;
    }

    let _ = with_fcitx_proxy(|proxy| {
        if let Some(input_method) = saved_state.input_method.as_deref() {
            let _ = proxy.call_method("SetCurrentIM", &(input_method));
        }

        let _ = proxy.call_method("Activate", &());
    });
}

fn with_fcitx_proxy(action: impl FnOnce(&Proxy<'_>)) -> Option<()> {
    if should_skip() {
        return None;
    }

    let connection = Connection::session().ok()?;
    let proxy = Proxy::new(&connection, FCITX_DESTINATION, FCITX_PATH, FCITX_INTERFACE).ok()?;
    action(&proxy);
    Some(())
}

fn should_skip() -> bool {
    let ssh = std::env::var_os("SSH_TTY").is_some() || std::env::var_os("SSH_CONNECTION").is_some();
    let graphical =
        std::env::var_os("DISPLAY").is_some() || std::env::var_os("WAYLAND_DISPLAY").is_some();

    ssh || !graphical
}

fn call_state(proxy: &Proxy<'_>) -> zbus::Result<i32> {
    proxy.call_method("State", &())?.body().deserialize()
}

fn call_current_input_method(proxy: &Proxy<'_>) -> zbus::Result<String> {
    proxy
        .call_method("CurrentInputMethod", &())?
        .body()
        .deserialize()
}
