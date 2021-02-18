"use strict";

window.onload = async function () {
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
    div.appendChild(canvas);

    const response = await fetch('mandelbrot.d64');
    const bytes = new Uint8Array(await response.arrayBuffer());

    function loadFiles() {
        FS.createDataFile('/', 'mandelbrot.d64', bytes, true, true);
    }

    const viceArguments = ['+sound', '-autostart', 'mandelbrot.d64', ];

    window.Module = {
        preRun: [loadFiles],
        arguments: viceArguments,
        canvas: canvas
    };

    const script = document.createElement('script');
    script.src = "c64/x64.js";
    document.head.appendChild(script); 
}