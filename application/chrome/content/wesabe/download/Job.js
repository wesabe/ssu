wesabe.provide('download.Job');

wesabe.download.Job = function(jobid, fid, creds, user_id, options) {
  this.jobid = jobid;
  this.fid = fid;
  this.creds = creds;
  this.user_id = user_id;
  this.status = 202;
  this.version = 0;
  this.data = {};
  this.options = options || {};
  this.options.goals = this.options.goals || ['statements'];
  this.timer = new wesabe.util.Timer();
};

wesabe.download.Job.prototype.update = function(result, data) {
  this.version++;
  this.result = result;
  if (data) {
    this.data[result] = data;
  }
  wesabe.info('Updating job to: ', result);
  wesabe.trigger(this, 'update');
};

wesabe.download.Job.prototype.suspend = function(result, data, callback) {
  this.version++;
  var player = this.player;
  this.result = result;
  this.data[result] = data;
  if (callback) wesabe.bind(player, 'timeout', callback);
  wesabe.one(this, 'resume', function() {
    if (callback) wesabe.unbind(player, 'timeout', callback);
  });
  wesabe.warn('Suspending job for ', result, '=', data);
  wesabe.trigger(this, 'update suspend');
};

wesabe.download.Job.prototype.resume = function(creds) {
  wesabe.warn('Resuming job');
  wesabe.trigger(this, 'resume');
  this.update('resumed');
  this.player.resume(creds);
};

wesabe.download.Job.prototype.fail = function(status, result) {
  this.finish(status, result, false);
};

wesabe.download.Job.prototype.succeed = function(status, result) {
  this.finish(status, result, true);
};

wesabe.download.Job.prototype.finish = function(status, result, successful) {
  this.version++;
  var event = successful ? 'succeed' : 'fail';
  this.done = true;
  if (typeof this.player.finish == 'function')
    this.player.finish();
  this.status = status || (successful ? 200 : 400);
  this.result = result || (successful ? 'ok' : 'fail');
  wesabe.trigger(this, 'update ' + event + ' complete');
  this.timer.end('Total');

  var org = this.player.org;
  var summary = this.timer.summarize(), line = [], total = parseFloat(summary['Total']);

  wesabe.info('Job completed ',successful?'':'un','sucessfully for ',org,' (',this.fid,')',
              ' with status ',this.status,' (',this.result,') in ',
              Math.round(total/1000,2),'s');


  for (var label in summary) {
    if (label == 'Total') continue;

    line.push(label+': ');
    line.push(summary[label]);
    line.push('ms');
    line.push(' (');
    line.push(parseInt((summary[label]/total)*100));
    line.push('%)');
    line.push(', ');
  }
  line.push('Total: ');
  line.push(total);
  line.push('ms');

  wesabe.info.apply(wesabe, line);
};

wesabe.download.Job.prototype.start = function() {
  var self = this;

  this.player = wesabe.download.Player.build(this.fid);
  this.player.job = this;

  wesabe.info('Starting job for ',this.player.org,' (',this.fid,')');
  this.player.start(this.creds, document.getElementById('playback-browser'));

  wesabe.trigger(this, 'begin');
  this.timer.start('Total');
  this.nextGoal();
};

wesabe.download.Job.prototype.nextGoal = function() {
  if (this.options.goals.length)
  {
    this.goal = this.options.goals.shift();
    wesabe.info('Starting new goal: ', this.goal);

    if (this.player.page)
      this.player.triggerDispatch();

    return this.goal;
  }

  this.player.onLastGoalFinished();
};
