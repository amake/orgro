//
//  PreprocessingJavaScript.js
//  Runner
//
//  Created by Aaron Madlon-Kay on 2025/11/25.
//

var MyExtensionJavaScriptClass = function() {};

MyExtensionJavaScriptClass.prototype = {
    run: function(arguments) {
        arguments.completionFunction({
            "baseURI": document.baseURI,
            // ?. operator available since iOS 13.4
            // https://caniuse.com/mdn-javascript_operators_optional_chaining
            "title": document.querySelector("head title")?.text.trim(),
            "selection": window.getSelection().toString().trim(),
        });
    },

    finalize: function(arguments) {}
};

var ExtensionPreprocessingJS = new MyExtensionJavaScriptClass;
