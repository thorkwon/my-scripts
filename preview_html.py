#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
# ]
# ///
import argparse
import html
import http.server
import io
import ipaddress
import json
import urllib.parse
from pathlib import Path

DEFAULT_PORT = 33333
DEFAULT_BIND = "127.0.0.1"

MD_VIEWER_TEMPLATE = """<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title} - Markdown Preview</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/github-markdown-css@5.9.0/github-markdown.min.css" integrity="sha384-mYBW/AGDT6JhlmN0DlBZPH4430+HhjMvn1xOSmsXnjSDn+zfyMwb3xCym6H5ICgn" crossorigin="anonymous">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github.min.css" integrity="sha384-eFTL69TLRZTkNfYZOLM+G04821K1qZao/4QLJbet1pP4tcF+fdXq/9CdqAbWRl/L" crossorigin="anonymous" id="hljs-light">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github-dark.min.css" integrity="sha384-wH75j6z1lH97ZOpMOInqhgKzFkAInZPPSPlZpYKYTOqsaizPvhQZmAtLcPKXpLyH" crossorigin="anonymous" id="hljs-dark" media="(prefers-color-scheme: dark)">
  <script src="https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js" integrity="sha384-/TQbtLCAerC3jgaim+N78RZSDYV7ryeoBCVqTuzRrFec2akfBkHS7ACQ3PQhvMVi" crossorigin="anonymous"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked-highlight@2.2.4/lib/index.umd.min.js" integrity="sha384-dwtONjF3cowPvkC6KHs+5ITqp94YuQV+1jCZ2KtfyqNQ+PDzf9EwbuPH8tcknWo5" crossorigin="anonymous"></script>
  <script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js" integrity="sha384-F/bZzf7p3Joyp5psL90p/p89AZJsndkSoGwRpXcZhleCWhd8SnRuoYo4d0yirjJp" crossorigin="anonymous"></script>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.8/dist/mermaid.min.js" integrity="sha384-N3QqR/7q+xm3BGX+CBbNI8AUmRRqcsDzToy+0z1NLDI0QmTKW8zvwLvqulJgk3dP" crossorigin="anonymous"></script>
  <script src="https://cdn.jsdelivr.net/npm/dompurify@3.4.15/dist/purify.min.js" integrity="sha384-uUMu9JDY09vBzRf9SPcK2VgUj+W/70J6Soc+Dded5P474ElQ63iv9j5N3DE7Kp3N" crossorigin="anonymous"></script>
  <style>
    :root {{
      color-scheme: light dark;
    }}
    body {{
      margin: 0;
      padding: 0;
      background-color: var(--color-canvas-default, #ffffff);
      color: var(--color-fg-default, #1f2328);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif;
    }}
    @media (prefers-color-scheme: dark) {{
      body {{
        background-color: #0d1117;
        color: #e6edf3;
      }}
    }}
    .preview-header {{
      position: sticky;
      top: 0;
      z-index: 100;
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 24px;
      background-color: rgba(246, 248, 250, 0.85);
      backdrop-filter: blur(8px);
      border-bottom: 1px solid #d0d7de;
      font-size: 14px;
    }}
    @media (prefers-color-scheme: dark) {{
      .preview-header {{
        background-color: rgba(22, 27, 34, 0.85);
        border-bottom: 1px solid #30363d;
      }}
    }}
    .preview-filename {{
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 8px;
    }}
    .preview-actions {{
      display: flex;
      gap: 8px;
    }}
    .preview-btn {{
      padding: 5px 12px;
      font-size: 13px;
      font-weight: 500;
      border: 1px solid #d0d7de;
      border-radius: 6px;
      background-color: #f6f8fa;
      color: #24292f;
      text-decoration: none;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      transition: background-color 0.2s, border-color 0.2s;
    }}
    .preview-btn:hover {{
      background-color: #f3f4f6;
    }}
    @media (prefers-color-scheme: dark) {{
      .preview-btn {{
        background-color: #21262d;
        border-color: #363b42;
        color: #c9d1d9;
      }}
      .preview-btn:hover {{
        background-color: #30363d;
      }}
    }}
    .markdown-body {{
      box-sizing: border-box;
      min-width: 200px;
      max-width: 980px;
      margin: 0 auto;
      padding: 32px 24px;
    }}
    .mermaid {{
      display: flex;
      justify-content: center;
      margin: 1.5rem 0;
    }}
  </style>
</head>
<body>
  <div class="preview-header">
    <div class="preview-filename">
      <span>📄</span>
      <span>{filename}</span>
    </div>
    <div class="preview-actions">
      <button class="preview-btn" id="toggleViewBtn" onclick="toggleView()">Raw 보기</button>
      <button class="preview-btn" onclick="copyRaw()">복사</button>
      <a class="preview-btn" href="?raw=1">원본(Raw) 링크</a>
    </div>
  </div>
  <main class="markdown-body" id="content">
    <pre id="raw-content" style="display:none; white-space: pre-wrap; font-family: monospace;">{escaped_content}</pre>
    <div id="rendered-content"></div>
  </main>
  <script>
    const rawMarkdown = {md_json};
    let isRaw = false;

    function render() {{
      if (window.marked && window.DOMPurify) {{
        const mh = window.markedHighlight && window.markedHighlight.markedHighlight;
        if (mh) {{
          marked.use(mh({{
            langPrefix: 'hljs language-',
            highlight(code, lang) {{
              if (lang && hljs.getLanguage(lang)) {{
                try {{
                  return hljs.highlight(code, {{ language: lang }}).value;
                }} catch (e) {{}}
              }}
              return hljs.highlightAuto(code).value;
            }}
          }}));
        }}
        marked.setOptions({{ breaks: true, gfm: true }});
        const renderedMarkdown = marked.parse(rawMarkdown);
        document.getElementById('rendered-content').innerHTML = DOMPurify.sanitize(
          renderedMarkdown,
          {{ SANITIZE_NAMED_PROPS: true }}
        );

        if (window.mermaid) {{
          try {{
            mermaid.initialize({{
              startOnLoad: false,
              theme: window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default'
            }});
            document.querySelectorAll('pre code.language-mermaid').forEach((el) => {{
              const pre = el.parentElement;
              const div = document.createElement('div');
              div.className = 'mermaid';
              div.textContent = el.textContent;
              pre.replaceWith(div);
            }});
            mermaid.run();
          }} catch (e) {{
            console.error('Mermaid render error:', e);
          }}
        }}
      }} else {{
        document.getElementById('raw-content').style.display = 'block';
      }}
    }}

    function toggleView() {{
      isRaw = !isRaw;
      const rawEl = document.getElementById('raw-content');
      const renderedEl = document.getElementById('rendered-content');
      const btn = document.getElementById('toggleViewBtn');
      if (isRaw) {{
        rawEl.style.display = 'block';
        renderedEl.style.display = 'none';
        btn.textContent = 'Preview 보기';
      }} else {{
        rawEl.style.display = 'none';
        renderedEl.style.display = 'block';
        btn.textContent = 'Raw 보기';
      }}
    }}

    function copyRaw() {{
      navigator.clipboard.writeText(rawMarkdown).then(() => {{
        alert('마크다운 본문이 클립보드에 복사되었습니다.');
      }}).catch(() => {{
        const textarea = document.createElement('textarea');
        textarea.value = rawMarkdown;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        alert('마크다운 본문이 클립보드에 복사되었습니다.');
      }});
    }}

    render();
  </script>
</body>
</html>
"""


class UTF8RequestHandler(http.server.SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def __init__(self, *args, allowed_ips=None, **kwargs):
        self.allowed_ips = allowed_ips
        super().__init__(*args, **kwargs)

    def parse_request(self):
        if not super().parse_request():
            return False
        if self.allowed_ips:
            client_ip = ipaddress.ip_address(self.client_address[0])
            if not client_ip.is_loopback and client_ip not in self.allowed_ips:
                self.send_error(http.HTTPStatus.FORBIDDEN, "Client IP is not allowed")
                return False
        return True

    def guess_type(self, path):
        # .md 파일은 raw 요청 시 브라우저에서 다운로드되지 않고 텍스트로 바로 보이도록 text/plain 지정
        if path.endswith((".md", ".markdown")):
            return "text/plain; charset=utf-8"

        ctype = super().guess_type(path)
        # text 타입인데 charset이 지정되지 않은 경우 utf-8 추가
        if ctype and ctype.startswith("text/") and "charset" not in ctype:
            ctype += "; charset=utf-8"
        return ctype

    def send_head(self):
        # 쿼리 파라미터 확인 (?raw=1 여부)
        parsed_url = urllib.parse.urlsplit(self.path)
        query_params = urllib.parse.parse_qs(parsed_url.query)
        is_raw = "raw" in query_params and query_params["raw"][0] in ("1", "true", "yes")

        try:
            path = Path(self.translate_path(parsed_url.path)).resolve()
            serve_root = Path(self.directory).resolve()
            path.relative_to(serve_root)
        except (OSError, RuntimeError, ValueError):
            self.send_error(http.HTTPStatus.FORBIDDEN, "Path is outside the serving root")
            return None

        if not is_raw and path.is_file() and str(path).endswith((".md", ".markdown")):
            return self.render_markdown(path)

        return super().send_head()

    def render_markdown(self, file_path):
        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
        except OSError:
            self.send_error(http.HTTPStatus.NOT_FOUND, "File not found")
            return None

        filename = Path(file_path).name
        # 스크립트 태그 탈출 방지
        safe_json = json.dumps(content).replace("</", "<\\/")
        rendered_html = MD_VIEWER_TEMPLATE.format(
            title=html.escape(filename),
            filename=html.escape(filename),
            escaped_content=html.escape(content),
            md_json=safe_json,
        )
        encoded = rendered_html.encode("utf-8")

        self.send_response(http.HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()

        return io.BytesIO(encoded)


def run():
    parser = argparse.ArgumentParser(
        description="UTF-8 지원 HTTP 서버 (Safari/Chrome 한글 깨짐 방지)"
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=None,
        help="서빙할 루트 디렉터리 (기본값: 현재 디렉터리)",
    )
    parser.add_argument(
        "-p",
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help=f"서버 포트 (기본값: {DEFAULT_PORT})",
    )
    parser.add_argument(
        "-b",
        "--bind",
        type=str,
        default=DEFAULT_BIND,
        help=f"바인딩 주소 (기본값: {DEFAULT_BIND})",
    )
    access_group = parser.add_mutually_exclusive_group()
    access_group.add_argument(
        "--public",
        action="store_true",
        default=False,
        help="모든 네트워크 인터페이스에서 접근 허용 (0.0.0.0 바인딩)",
    )
    access_group.add_argument(
        "--allow-ip",
        type=ipaddress.IPv4Address,
        action="append",
        default=None,
        metavar="IP",
        help="지정한 클라이언트 IPv4와 localhost만 허용 (반복 지정 가능, 0.0.0.0 바인딩)",
    )
    args = parser.parse_args()

    serve_dir = Path(args.directory).expanduser().resolve() if args.directory else Path.cwd()
    bind_addr = "0.0.0.0" if args.public or args.allow_ip else args.bind
    allowed_ips = set(args.allow_ip) if args.allow_ip else None

    def handler_factory(*h_args, **h_kwargs):
        return UTF8RequestHandler(
            *h_args, directory=str(serve_dir), allowed_ips=allowed_ips, **h_kwargs
        )

    http.server.ThreadingHTTPServer.allow_reuse_address = True

    with http.server.ThreadingHTTPServer((bind_addr, args.port), handler_factory) as httpd:
        print(f" Serving HTTP on {bind_addr} port {args.port} ...")
        print(f" Root directory : {serve_dir}")
        if allowed_ips:
            print(f" Allowed clients: localhost, {', '.join(map(str, args.allow_ip))}")
        print(" Press Ctrl+C to stop.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n Keyboard interrupt received, exiting.")


if __name__ == "__main__":
    run()
