import os
import socket
import sys

from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello():
    return f"""<!doctype html>
<html>
  <head><title>Python Hello World</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello World from Python</h1>
    <p>Served by Flask inside a Docker container</p>
    <p>Python {sys.version.split()[0]} &middot; host {socket.gethostname()}</p>
  </body>
</html>"""


@app.route("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
