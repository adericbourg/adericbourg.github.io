#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Alban Dericbourg'
AUTHOR_LINK = u'http://www.dericbourg.net'
SITENAME = u'Blog bloquant'
SITEURL = ''

TWITTER_HANDLE = u'@adericbourg'

PATH = 'content'
STATIC_PATHS = ['extra/CNAME', 'images']
EXTRA_PATH_METADATA = {'extra/CNAME': {'path': 'CNAME'},}

TIMEZONE = 'Europe/Paris'

DEFAULT_LANG = u'fr'

THEME = 'theme'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

GITHUB_URL = 'https://github.com/adericbourg'
TWITTER_URL = 'https://twitter.com/adericbourg'

# Social widget

DEFAULT_PAGINATION = 10

ARTICLE_URL = '{date:%Y}/{date:%m}/{date:%d}/{slug}/'
ARTICLE_SAVE_AS = '{date:%Y}/{date:%m}/{date:%d}/{slug}/index.html'

PAGE_URL = '{slug}/'
PAGE_SAVE_AS = '{slug}/index.html'

ARCHIVES_SAVE_AS = 'archives/index.html'
ARCHIVES_URL = 'archives/'

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True
