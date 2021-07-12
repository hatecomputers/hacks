#!/usr/bin/node


const fs = require('fs');
const http = require('http');
const exec = require('child_process').exec;

const args = process.argv;
const path = args[2];
const file = args[3] || `${path}/index.html`;

const getImage = (file) => /png|jpg/.test(file.substr(-3))

const getUrl = (file) => file.replace('-','://').replace('.png','');

const getTemplate = (images = []) => {
	return `<div style="display: flex; flex-wrap: wrap; margin-bottom: 10px; justify-content: space-between;">${images.map(image =>`<div style="width: 30%; margin-bttom: 10px;"><img style="width: 100%;" src="${image}" /><div class="url"><a href="${getUrl(image)}">${getUrl(image)}</a></div></div>`).join("\n")}</div>`
}

fs.readdir(path, (err, response) => {
   const files = [...response];
   const images = files.filter(getImage);	
   const template = getTemplate(images)

   fs.writeFile(file, template,'utf8', (err, response) => {
   	if (err) throws `Couldnt write in the ${file}.`;

	// console.log(`${file} created successfully.\n now do 'python3 -m http-server'`);
   	exec(`cd ${path}; python3 -m http.server`, (error, stdout, stderr) => {
		if (error) {
			console.dir(error)
			process.exit(error.code)
		}

	})
	console.log('Serving running on port 8000');
   })
})

console.log(banner);
