"use strict";

window.onload = function () {
    const screenshot = [...document.getElementsByTagName('img')].find(x => x.alt == "screenshot");

    if (screenshot == null){
        return;
    }

    const div = document.createElement("div");
    div.id = "screen_container";
    screenshot.parentElement.insertAdjacentElement("beforebegin", div);
    const divdiv = document.createElement("div");
    divdiv.appendChild(screenshot);
    div.appendChild(divdiv)
    div.nextSibling.remove();

    const canvas = document.createElement("canvas");
    canvas.id ="screen_canvas";
    canvas.style.width = "320px";
    canvas.style.height = "200px";

    div.appendChild(canvas);


    const emulator = new V86Starter({
        wasm_path: "scripts/v86/v86.wasm",
        memory_size: 1 * 1024 * 1024,
        vga_memory_size: 1 * 1024 * 1024,
        screen_container: document.getElementById("screen_container"),
        bios: {
            url: "scripts/v86/seabios.bin",
        },
        vga_bios: {
            url: "scripts/v86/vgabios.bin",
        },
        fda: {
            url: "bin/boot.img",
        },
        autostart: true,
    });

    emulator.keyboard_send_keys(false);
    emulator.mouse_set_status(false);


    canvas.oncontextmenu = () => false;

    canvas.addEventListener("mouseenter",
        () => {
            emulator.keyboard_send_keys(true);
            emulator.mouse_set_status(true);
        }
    );

    canvas.addEventListener("mouseleave",
        () => {
            emulator.keyboard_send_keys(false);
            emulator.mouse_set_status(false);
        }
    );
}