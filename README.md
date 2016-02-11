# php7-laravel
Ubuntu 14.04 base php7 and laravel...

### Install docker && docker compose
please refer to these tutorials:
* install docker (https://docs.docker.com/installation/ubuntulinux/)
* install docker compose (fig alternative) (https://docs.docker.com/compose/install/)

### Build the homestead image
```shell
git clone https://github.com/gyuha/php7-laravel.git
cd php7-laravel
docker build -t php7-laravel .
```

### Launch your containers
There are only two containers to run. web container ( includes everything except your database ), and mariadb container.
```shell
sudo docker-compose up -d
```


### SSH into the container (password: secret):
```shell
ssh -p 2222 homestead@localhost
```


### Add a virtual host
Assuming you mapped your apps folder to ```/apps``` (you can change mappings in the docker-compose.yml file, it's prefered to use absolute paths), you can do:
```shell
cd / && ./serve.sh myapp.dev /apps/myapp/public
```
In the host, update ``` /etc/hosts ``` to include your app domain:
```shell
127.0.0.1               myapp.dev
```
