import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import * as db from './db';

let app = Elm.Main.init({
  flags: { 
    shareApiEnabled: navigator.share !== undefined,
    backendApi: process.env.BACKEND_API
  },
  node: document.getElementById('root')
});


const getFavouriteHomes = () => {
    db.getFavouriteHomes().onsuccess = function (event) {
      app.ports.returnFavouriteHomes.send(event.target.result);
    };
};

const copyToClipboard = string => {
  const el = document.createElement('textarea');
  el.value = string;
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

const showError = string => {
  app.ports.showError.send(string);
}

app.ports.copyToClipboard.subscribe(function (data) {
  copyToClipboard(data);
  showError("Copied to clipboard");
});

app.ports.favouriteHome.subscribe((home) =>{
  let request = db.favouriteHome(home);
  request.onsuccess = (event)=> {
    app.ports.showError.send("Added to favourites");
    getFavouriteHomes();
  };
  request.onerror = (event) => {
    app.ports.showError.send("Already a favourite");
  };
});

app.ports.removeFavouriteHome.subscribe((home) => {
  let request = db.removeFavouriteHome(home)
  request.onsuccess = (event) => {
    showError("Removed");
    getFavouriteHomes();
  };
  request.onerror = (event) => {
    console.error("Attempted to remove non-favourite home");
  };
});

app.ports.getFavouriteHomes.subscribe(getFavouriteHomes);

app.ports.openLink.subscribe((link) => {
  window.open(link, "_blank");
});



// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();


