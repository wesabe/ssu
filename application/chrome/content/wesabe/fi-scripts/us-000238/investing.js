wesabe.provide('fi-scripts.us-000238.investing', {
  filter: function() {
    if (page.present(e.investing.transition.continueButton) || 
        page.present(e.investing.login.user.label) ||
        page.present(e.investing.overview.returnButton)) {
      skipAccount('Investment account encountered, skipping (account=',tmp.account,')');
      
      // the user has a choice of whether or not they want to be shown the 
      // "You're now entering the Investments area" or not, so how we get back
      // depends on whether they've checked the "don't show me this" box
      if (page.present(e.investing.transition.returnButton)) {
        // they haven't checked the box (see investments-transition)
        page.click(e.investing.transition.returnButton);
      } else if (page.present(e.investing.login.user.label)) {
        // they have checked the box and are being asked to log in
        page.click(e.investing.login.cancel);
      } else if (page.present(e.investing.overview.returnButton)) {
        // they have checked the box or we somehow ended up in the investments section
        page.click(e.investing.overview.returnButton);
      } else {
        // not sure what to do here, just go back
        page.back();
      }
      
      return false; // no, don't dispatch
    }
    
    // no return means no opinion
  }, 
  
  elements: {
    investing: {
      transition: {
        continueButton: [
          '//a[contains(string(.), "Continue to Online Investing")]', 
        ], 
        
        returnButton: [
          '//a[contains(string(.), "Return to Online Banking")]', 
        ], 
      }, 
      
      login: {
        user: {
          label: [
            '//label[contains(string(.), "Online Investing User ID")]'
          ], 
        }, 
        
        cancelButton: [
          '//a[contains(@href, "acctOverview")]', 
        ], 
      }, 

      overview: {
        returnButton: [
          '//a[contains(@title, "Return to Online Banking")]',
          '//span[@id="returnToOnlineBanking"]//a[contains(@href, "acctOverview")]',
        ],
      },
    }, 
  }, 
});
