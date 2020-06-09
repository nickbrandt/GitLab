# Ensure Oj runs in json-gem compatibility mode by default
#
# Oj pollutes ActiveRecord by default without being told to,
# so this setting is required in order to ensure it maintains
# compatibility with the existing system.

Oj.default_options = { mode: :rails }
