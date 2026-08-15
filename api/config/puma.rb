# frozen_string_literal: true

# Each active interview occupies 1 Puma thread (audio WebSocket + Gemini WS).
# With 16 threads and 2 workers (32 total), the server handles ~10 concurrent
# interviews plus REST API headroom.

max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 16)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }

threads min_threads_count, max_threads_count

# macOS + Objective-C can crash when Puma forks workers after application
# preload. Keep development single-process to avoid fork-related crashes.
#
# Production keeps the intended multi-worker setup.
rails_env = ENV.fetch('RAILS_ENV', 'development')

if rails_env == 'development'
  workers 0
else
  workers ENV.fetch('WEB_CONCURRENCY', 2)
end

# Allow long-running development WebSocket connections.
worker_timeout 3600 if rails_env == 'development'

# Keep long-lived WebSocket connections alive between Puma keep-alive checks.
# Interviews run 30-90 minutes — connections must not time out.
persistent_timeout ENV.fetch('PUMA_PERSISTENT_TIMEOUT', 300).to_i
first_data_timeout ENV.fetch('PUMA_FIRST_DATA_TIMEOUT', 30).to_i

port ENV.fetch('PORT', 3001)

environment rails_env

pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# Preload the application before forking production workers.
#
# In development workers are disabled above, so preload_app! does not cause
# Puma to fork development workers.
preload_app!

on_worker_boot do
  # Reconnect ActiveRecord after the worker is forked.
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)

  # Restart the EventMachine reactor in each forked worker.
  #
  # preload_app! forks after EM may have started in the master process.
  # The reactor thread cannot safely be shared across fork boundaries.
  unless EventMachine.reactor_running?
    ready = Queue.new

    Thread.new do
      EventMachine.run do
        ready.push(:ok)
      end
    end

    ready.pop
  end
end

plugin :tmp_restart