import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

let app = Elm.Main.init({
  flags: { shareApiEnabled: navigator.share !== undefined },
  node: document.getElementById('root')
});

app.ports.copyToClipboard.subscribe(function (data) {
  copyToClipboard(data);
  app.ports.showError.send("Copied to clipboard");
});


const indexdb = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
const DB_NAME = "FS_Mieszkania_DB"
var db;
const request = indexdb.open(DB_NAME, 1);
request.onerror = function (event) {
  console.log("Cannot use indexed db");
};
request.onsuccess = function (event) {
  db = event.target.result;
  db.onerror = (event) =>{
    console.error(JSON.stringify(event))
  };
};

request.onupgradeneeded = function (event) {
  var db = event.target.result;

  // Create an objectStore to hold information about our customers. We're
  // going to use "ssn" as our key path because it's guaranteed to be
  // unique - or at least that's what I was told during the kickoff meeting.
  var objectStore = db.createObjectStore("favouriteHomes", { keyPath: "id" });

  // Create an index to search customers by name. We may have duplicates
  // so we can't use a unique index.
  objectStore.createIndex("id", "id", { unique: true });
};

app.ports.favouriteHome.subscribe((home) =>{
  var transaction = db.transaction(["favouriteHomes"], "readwrite");
  var objectStore = transaction.objectStore("favouriteHomes");
  console.log(home);
  var request = objectStore.add(home);
});

// var request = db.transaction(["customers"], "readwrite")
//   .objectStore("customers")
//   .delete("444-44-4444");
console.log(app.ports);
app.ports.getFavouriteHomes.subscribe(() => {
  var objectStore = db.transaction("favouriteHomes").objectStore("favouriteHomes");
  objectStore.getAll().onsuccess = function (event) {
    app.ports.returnFavouriteHomes.send(event.target.result);
  };
});

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


