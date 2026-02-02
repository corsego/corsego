# See https://ddnexus.github.io/pagy/extras
# Pagy configuration

# Bootstrap extra - enables pagy_bootstrap_nav helper
require 'pagy/extras/bootstrap'

# Overflow extra - handles page overflow gracefully
# See https://ddnexus.github.io/pagy/docs/extras/overflow/
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :last_page

# Configure defaults before the hash is frozen
# Pagy defaults are configured in the gem, this file customizes them
