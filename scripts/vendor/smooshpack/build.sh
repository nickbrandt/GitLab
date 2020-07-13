rm -rf ./package ./www

wget $(npm view smooshpack@0.0.62 dist.tarball)

tar -xzf smooshpack-0.0.62.tgz package/sandpack

rm smooshpack-0.0.62.tgz
mv package/sandpack www
rm -r package

patch ./www/index.html ./index.html.patch
rm ./www/*service-worker.js

make
