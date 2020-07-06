current_dir=$(pwd)

docker run -it --rm -v $current_dir/www:/www/data -v $current_dir/local:/www/data/local -v $current_dir/nginx/nginx.conf:/etc/nginx/nginx.conf -v $current_dir/nginx/error_logs:/etc/nginx/error_logs -v ~/dev/certs/:/etc/nginx/certs -p 443:443 nginx:latest
