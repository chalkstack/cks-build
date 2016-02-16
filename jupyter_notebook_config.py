c = get_config()

# Set options for certfile, ip, password, and toggle off browser auto-opening
c.NotebookApp.certfile = u'/etc/certs/mycert.pem'
c.NotebookApp.keyfile = u'/etc/certs/mykey.key'

# Set ip to '*' to bind on all interfaces (ips) for the public server
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False

# It is a good idea to set a known, fixed port for server access
c.NotebookApp.port = 8899
