// function googleLogin(googleUser) {
//  var profile = googleUser.getBasicProfile();
// 	console.log("Connected to Google")
//  console.log('Name: ' + profile.getGivenName());
//  console.log('Last Name: ' + profile.getFamilyName());
//  console.log('Email: ' + profile.getEmail());
// 	var first_name = profile.getGivenName();
// 	var last_name = profile.getFamilyName();
// 	var email = profile.getEmail();
// 	window.location = "/google?first_name=" + first_name +  '&last_name=' + last_name + '&email=' + email;	 
// }

function signOut() {
	var auth2 = gapi.auth2.getAuthInstance();
	auth2.signOut().then(function () {
		console.log('User signed out.');
	});
}

// function onLoad() {
// 	gapi.load('auth2', function() {
// 		gapi.auth2.init();
// 	});
// }

// New Login Script so we can customize the css and actual login button
  var googleUser = {};
  var startApp = function() {
    gapi.load('auth2', function(){
      // Retrieve the singleton for the GoogleAuth library and set up the client.
      auth2 = gapi.auth2.init({
        client_id: '182370847863-48of9fa5cjevk9fqrd5jta7vredjr16e.apps.googleusercontent.com',
        cookiepolicy: 'single_host_origin',
        // Request scopes in addition to 'profile' and 'email'
        //scope: 'additional_scope'
      });
      attachSignin(document.getElementById('customBtn'));
    });
  };

  function attachSignin(element) {
    console.log(element.id);
    auth2.attachClickHandler(element, {},
        function(googleUser) {
       first_name =  googleUser.getBasicProfile().getGivenName();
			 last_name =  googleUser.getBasicProfile().getFamilyName();
			 email =  googleUser.getBasicProfile().getEmail();
			console.log(googleUser.getBasicProfile().getGivenName());
			console.log(googleUser.getBasicProfile().getFamilyName());
			console.log(googleUser.getBasicProfile().getEmail());
			window.location = "/google?email=" + email + "&first_name=" + first_name + "&last_name=" + last_name 	 
        }, function(error) {
          alert(JSON.stringify(error, undefined, 2));
        });
		
  }

startApp();