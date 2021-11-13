# See https://ddnexus.github.io/pagy/extras
require "pagy/extras/bootstrap"
require "pagy/extras/overflow"
# Pagy::DEFAULT[:overflow] = :empty_page    # default  (other options: :last_page and :exception)
Pagy::DEFAULT[:overflow] = :last_page

Pagy::DEFAULT[:items] = 12 # default
