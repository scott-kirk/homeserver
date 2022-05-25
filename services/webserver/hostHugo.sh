#sudo docker run -it -v ~/repos/scottkirk.dev/game:/usr/src/game rust-wasm:latest \
#	/bin/sh -c "cd /usr/src/game && wasm-pack build --target web"
sudo docker run -it -v ~/repos/scottkirk.dev:/src jakejarvis/hugo-extended:latest
sudo chown scott:scott -R ~/repos/scottkirk.dev
rm -rf ~/services/webserver/data/public/*
mv ~/repos/scottkirk.dev/public/* ~/services/webserver/data/public/
