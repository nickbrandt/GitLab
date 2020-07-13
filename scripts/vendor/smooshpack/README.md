## Smooshpack service worker POC

**How do I run this thing?**

You must have `https` enabled in your local gdk

1. Run `./build.sh`
2. Run `./start.sh`

If you make changes to any of the files in `local/` you can run `make`.

You'll have to do some handholding to get the service worker to update (like unregister it in your browser or check "update on reload")
