wesabe.download.Player.register({
  fid: 'us-001201', 
  org: 'Huntington National Bank', 
  
  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://onlinebanking.huntington.com/");
    }, 
    
    login: function() {
      job.update('auth.creds');
      
      page.fill(e.login.username.field, answers.username);
      page.fill(e.login.password.field, answers.password);
      page.click(e.login.continueButton);
    }, 
    
    security: function() {
      job.update('auth.security');
      action.answerSecurityQuestions();
    }, 
  }, 
  
  dispatch: function() {
    // let's get a better look
    page.dump();
    
    if (page.present(e.login.username.errors.invalid)) {
      return job.fail(401, 'auth.user.invalid');
    }
    
    if (page.present(e.login.password.errors.invalid)) {
      return job.fail(401, 'auth.pass.invalid');
    }
    
    if (page.present(e.security.errors.invalid)) {
      return job.fail(401, 'auth.security.invalid');
    }
    
    if (page.present(e.login.username.field) || page.present(e.login.password.field)) {
      return action.login();
    }
    
    if (page.present(e.security.questions)) {
      return action.security();
    }
    
    // hopefully we've logged in by this point, but we don't know 
    // what to do next, so just transition to "Getting accounts"
    job.update('account.placeholder');
    
    // wait a bit before saying that, sadly, we couldn't do it
    setTimeout(function() { job.fail(500, 'ssu.script.incomplete') }, 20*1000 /* 20s */);
  }, 
  
  extensions: {
    shouldDispatch: function(browser, page) {
      if (page.defaultView.frameElement && page.defaultView.frameElement.name != 'main') {
        log.debug("Skipping dispatch because frame isn't main (actual=", page.defaultView.frameElement.name, ")");
        return false;
      }
      return true;
    }, 
  }, 
  
  elements: {
    login: {
      username: {
        field: [
          '//form[@name="Login"]//input[@name="tbUserName"]', 
          '//input[@name="tbUserName" and @type="text"]', 
          '//form[@id="Login"]//input[@type="text"]', 
        ], 
        
        errors: {
          invalid: [
            '//form[@name="Login"]//*[@class="con-error-text" and contains(string(.), "Username")]', 
            '//form[@name="Login"]//text()[contains(., "must enter a valid Username")]', 
          ], 
        }, 
      }, 
      
      password: {
        field: [
          '//form[@name="Login"]//input[@name="tbPassword"]', 
          '//input[@name="tbPassword" and @type="password"]', 
          '//form[@id="Login"]//input[@type="password"]', 
        ], 
        
        errors: {
          invalid: [
          '//form[@name="Login"]//*[@class="con-error-text" and contains(string(.), "password")]', 
            '//form[@name="Login"]//text()[contains(., "invalid password")]', 
          ], 
        }, 
      }, 
      
      continueButton: [
        '//form[@name="Login"]//input[@name="btSubmit"]', 
        '//input[@name="btSubmit" and (@type="submit" or @type="image")]', 
        '//form[@name="Login"]//input[@type="submit" or @type="image"]', 
      ], 
    }, 
    
    security: {
      questions: [
        '//form[@name="Form1"]//*[@id="lblQuestion"]//text()', 
        '//*[@id="lblQuestion"]//text()', 
      ], 
      
      answers: [
        '//form[@name="Form1"]//input[@name="txtAnswer" and @type="password"]', 
        '//input[@name="txtAnswer" and @type="password"]', 
        '//input[@name="txtAnswer"]', 
      ], 
      
      continueButton: [
        '//form[@name="Form1"]//input[@name="btSubmit"]', 
        '//input[@name="btSubmit" and (@type="submit" or @type="image")]', 
        '//form[@name="Form1"]//input[@type="submit" or @type="image"]', 
      ], 
      
      errors: {
        invalid: [
          '//form[@name="Form1"]//*[@class="con-error-text"]', 
          '//form[@name="Form1"]//text()[contains(., "cannot verify the answer you provided")]', 
          '//text()[contains(., "cannot verify the answer you provided")]', 
        ], 
      }
    }, 
  }
});
