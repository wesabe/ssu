wesabe.provide('api.Uploader');

wesabe.api.Uploader = function(statement, wesabeId, nofx, job) {
  this.statement = statement;
  this.wesabeId = wesabeId;
  this.nofx = nofx;
  this.job = job;
};

wesabe.api.Uploader.prototype.upload = function() {
  var self = this, job = this.job;

  return wesabe.tryThrow('Uploader#upload', function(log) {
    var data = self.packStatement(self.statement, self.wesabeId, self.nofx);

    wesabe.api.post('upload/statement', null, data, {
      success: function(req) {
        log.info("Upload successful for wesabeId ",self.wesabeId,": ",req.responseText);
        wesabe.trigger(self, 'uploadSuccess', [self]);
        wesabe.trigger('uploadSuccess', [self]);
        wesabe.trigger(self, 'uploadComplete', [self]);
        wesabe.trigger('uploadComplete', [self]);
      },

      failure: function(req) {
        try {
          log.error("post error code " + req.status + " " + req.statusText);
        } catch (e) {
          log.error("no response. maybe we couldn't connect at all?");
        }
        wesabe.trigger(self, 'uploadFail', [self]);
        wesabe.trigger('uploadFail', [self]);
        wesabe.trigger(self, 'uploadComplete', [self]);
        wesabe.trigger('uploadComplete', [self]);
      }
    });
  });
};

wesabe.api.Uploader.prototype.packStatement = function(stmt, wesabeId, md) {
  return wesabe.tryThrow('Uploader#packStatement', function(log) {
    log.info("Preparing envelope for statement: \n" +
      stmt.substring(0, 27) + "\n ...\n w/ wesabe-id: " + wesabeId);

    // Create the DOM wrapper for the request
    var uploadDoc = document.implementation.createDocument("", "", null);
    var uploadElem = uploadDoc.createElement("upload");
    var stmtElem = uploadDoc.createElement("statement");
    stmtElem.setAttribute("wesabe_id", wesabeId);
    if (md != null) {
      log.info("md: ", md.nofx.balance, " : ", md.nofx.acctid, " : ", md.nofx.accttype);
      wesabe.tryCatch('Uploader#packStatement', function(log) {
        if (md.nofx.balance !== "-1")
          stmtElem.setAttribute("balance", md.nofx.balance);
        stmtElem.setAttribute("acctid", md.nofx.acctid);
        stmtElem.setAttribute("accttype", md.nofx.accttype);
      });
    }
    stmtElem.textContent = stmt;
    uploadElem.appendChild(stmtElem);
    uploadDoc.appendChild(uploadElem);

    return uploadDoc;
  });
};


wesabe.api.Uploader.prototype.sniffOfxField = function(stmt, fieldName) {
  var fieldIdx = stmt.indexOf('<' + fieldName + '>');
  if (fieldIdx >= 0) {
    fieldIdx += (fieldName.length+2);
    var fieldValue = stmt.substring(fieldIdx, stmt.length);
    fieldIdx = fieldValue.indexOf('<');
    fieldValue = fieldValue.substring(0, fieldIdx);
    return fieldValue.replace(/^\s+|\s+$/, '');
  }
  return '';
};
