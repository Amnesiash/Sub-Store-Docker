# 使用 Alpine 作为基础镜像
FROM alpine

# 设置工作目录
WORKDIR /opt/app

# 安装必要的软件包，包括 nodejs、curl 和 tzdata
RUN apk add --no-cache nodejs curl tzdata

# 设置时区环境变量
ENV TIME_ZONE=Asia/Shanghai 

# 设置时区
RUN cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone

# 下载 Sub-Store 后端和前端的相关文件
ADD https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js /opt/app/sub-store.bundle.js
ADD https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip /opt/app/dist.zip

# 解压前端文件，并将其移动到 frontend 目录
RUN unzip dist.zip; mv dist frontend; rm dist.zip

# 下载 http-meta 相关文件
ADD https://github.com/xream/http-meta/releases/latest/download/http-meta.bundle.js /opt/app/http-meta.bundle.js
ADD https://github.com/xream/http-meta/releases/latest/download/tpl.yaml /opt/app/data/tpl.yaml

# 下载 GeoLite 数据库文件
ADD https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb /opt/app/data/GeoLite2-Country.mmdb
ADD https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb /opt/app/data/GeoLite2-ASN.mmdb

# 下载 mihomo 文件并解压
RUN version=$(curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 'https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt') && \
  arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/) && \
  url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-$arch-$version.gz" && \
  curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 "$url" -o /opt/app/data/http-meta.gz && \
  gunzip /opt/app/data/http-meta.gz && \
  rm -rf /opt/app/data/http-meta.gz

# 修改目录权限
RUN chmod 777 -R /opt/app

# 启动命令，运行 HTTP-META 和 Sub-Store
CMD mkdir -p /opt/app/data; cd /opt/app/data; \
  META_FOLDER=/opt/app/data HOST=:: PORT=9876 node /opt/app/http-meta.bundle.js > /opt/app/data/http-meta.log 2>&1 & echo "HTTP-META is running..."; \
  SUB_STORE_BACKEND_API_HOST=:: SUB_STORE_FRONTEND_HOST=:: SUB_STORE_FRONTEND_PORT=7860 SUB_STORE_FRONTEND_PATH=/opt/app/frontend SUB_STORE_DATA_BASE_PATH=/opt/app/data SUB_STORE_MMDB_COUNTRY_PATH=/opt/app/data/GeoLite2-Country.mmdb SUB_STORE_MMDB_ASN_PATH=/opt/app/data/GeoLite2-ASN.mmdb node /opt/app/sub-store.bundle.js
