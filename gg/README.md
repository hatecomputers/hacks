# generate-gallery

Shitty node script that generates a somewhat ok gallery for image previewing. 

## How to use 

### Dependencies
* [nodejs](https://nodejs.dev/)
* [python3](https://www.python.org) (Optional)
* [http.server](https://docs.python.org/3/library/http.server.html) (Optional)

### Running 

I usually use this in conjunction with [gowitness](https://github.com/sensepost/gowitness). So the workflow would be something along those lines:
```
$ gowitness file -s <path-to-domains> -d <destination-directory> -T 1
$ gg <path-to-your-images>
```

As the output, you should get a `index.html` containing the gallery.

## Other info

By default, the script will run a server on port 9000. For this to work, you need to have python3 that comes with an `http.server` module. Best case scenario 
would be having a flag to turn this on/off but for the time being, if you don't want this comment line 29 to 36. 
