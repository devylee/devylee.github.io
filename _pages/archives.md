---
title   : Archives
layout  : page
current : archives
class   : post page page-archives
---

> The post archives by years and tags.

<!--more-->

### Years:

{% assign yearly_posts = site.posts | group_by_exp:"post", "post.date | date:'%Y'"%}
{% for year in yearly_posts %}
{%- capture year_path -%}/year/{{ year.name }}/{%- endcapture -%}
 * [<nobr>{{year.name}}<sub>({{year.size}})</sub></nobr>]({{ year_path | relative_url }})
{% endfor %}


### Tags:

{% for tag in site.tags %}
    {%- assign tag_key = tag[0] -%}
    {%- assign tag_info = site.data.tags[tag_key] -%}
    {%- capture tag_path -%}/tag/{{ tag_key | downcase | slugify }}/{%- endcapture -%}
  * [<nobr>{% if tag_info %}{{ tag_info.name }}{% else %}{{ tag[0] }}{% endif %}<sub>({{ tag[1] | size }})</sub></nobr>]({{ tag_path | relative_url }})
{% endfor%}

