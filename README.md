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
- Create a [server config file](https://isso-comments.de/docs/reference/server-config/)
- [Build and run the Docker image](https://isso-comments.de/docs/reference/installation/#using-docker)
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
