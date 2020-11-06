This is a [Jekyll](https://jekyllrb.com/) blog. To build:
```
bundle install 
bundle exec jekyll build
```
To develop locally:
```
bundle exec jekyll serve
```
To render Facebook/Instagram posts using oEmbed:
- Obtain a [Facebook oEmbed access token](https://developers.facebook.com/docs/plugins/oembed)
- Save `.env.example` as `.env`, with the access token above
- `source .env`
