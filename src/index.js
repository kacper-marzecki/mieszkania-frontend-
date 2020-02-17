import './main.css';
import './db.js';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

let app = Elm.Main.init({
  flags: { shareApiEnabled: navigator.share !== undefined },
  node: document.getElementById('root')
});

app.ports.copyToClipboard.subscribe(function (data) {
  copyToClipboard(data);
});

app.ports.showError.send("testerror");


const copyToClipboard = str => {
  const el = document.createElement('textarea'); 
  el.value = str;                                
  el.setAttribute('readonly', '');               
  el.style.position = 'absolute';
  el.style.left = '-9999px';                     
  document.body.appendChild(el);                 
  const selected =
    document.getSelection().rangeCount > 0      
      ? document.getSelection().getRangeAt(0)    
      : false;                                    
  el.select();                                    
  document.execCommand('copy');                  
  document.body.removeChild(el);                  
  if (selected) {                                
    document.getSelection().removeAllRanges();   
    document.getSelection().addRange(selected);   
  }
};

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();


