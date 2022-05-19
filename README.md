This is a [Jekyll](https://jekyllrb.com/) blog. To build:
```
bundle install
bundle exec jekyll build
```
To develop locally:
```
bundle exec jekyll serve
```
I use [Isso](https://posativ.org/isso/) for comments. Here are the steps to set it up:
- Create a [server config file](https://posativ.org/isso/docs/configuration/server/) - start from the [example](https://github.com/posativ/isso/blob/master/share/isso.conf) and rename to `isso.cfg`!
- [Build and run the Docker image](https://posativ.org/isso/docs/install/#build-a-docker-image)
- Wire it into the `nginx` server config:
```
    location /isso {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Script-Name /isso;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://localhost:8080;
    }
```
