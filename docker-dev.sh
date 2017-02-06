docker build -t one:dev -f Dockerfile.dev .
docker run --network prgrphstokyo_default \
  --link redis:redis \
  -e RACK_ENV=production \
  -e VIRTUAL_HOST=one.prgrphs.tokyo \
  -e VVERBOSE=1 \
  -e REDISTOGO_URL=redis://redis:6379 \
  -e QUEUE=* \
  -e MONGOHQ_URL=mongodb://mongo/one_production \
  --env-file ~/prgrphs.tokyo-private/env_files/one -ti \
  -v $(pwd):/usr/local/app \
  one:dev \
  bash -c "rm /tmp/.X99-lock || echo 'Lock not found, continuing normal setup' && xvfb-run bundle exec rake resque:work"
