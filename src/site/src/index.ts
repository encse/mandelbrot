import fs from 'fs';
import path from 'path';
import MarkdownIt from 'markdown-it'
import metadataParse from 'markdown-yaml-metadata-parser';
import sha256 from 'fast-sha256';
const inputDir = "../articles"
const outputDir = "../../docs"

for (let item of fs.readdirSync(inputDir)) {
    if(item.startsWith(".")){
        continue;
    }

    const css_version = Buffer
                .from(sha256(fs.readFileSync(path.join(outputDir, 'app.css'))))
                .toString('hex')
                .substring(0, 7);

    if (item.endsWith('.md')) {
        const file = item.replace("md", "html");
        const id = item.replace(".md", "").toLowerCase();

        const fpatIn = path.join(inputDir, item);
        const fpatOut = path.join(outputDir, file);
        const md = MarkdownIt({
            html: true
        });
        
        const {metadata, content} = metadataParse(fs.readFileSync(fpatIn, "utf-8"));

        const args = {
            screenshot: `images/${id}-screenshot.png`,
            file: file,
            content: md.render(content),
            css_version: css_version,
            nav_index: "",
            nav_x86: "",
            nav_c64: "",
            emulator: '<canvas id="screen_canvas"></canvas>',
            scripts: (metadata["scripts"]??[]).map(script => `<script src="${script}"></script>`).join("\n\t")
        }

        args["nav_"+id] = "active";
        

        let template = fs.readFileSync("src/template.html", "utf-8");

        
        for(let key of Object.keys(args)){
             template = template.replace('{'+key+'}', args[key]);
        }
        fs.writeFileSync(fpatOut, template);
    }
    
}


