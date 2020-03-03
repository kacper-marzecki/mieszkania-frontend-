const indexdb = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
const DB_NAME = "FS_Mieszkania_DB"
var db;

const request = indexdb.open(DB_NAME, 1);

request.onerror = function (event) {
    console.log("Cannot use indexed db");
};

request.onsuccess = function (event) {
    db = event.target.result;
    db.onerror = (event) => {
        console.error(JSON.stringify(event))
    };
};

request.onupgradeneeded = function (event) {
    var db = event.target.result;
    var objectStore = db.createObjectStore("favouriteHomes", { keyPath: "id" });
    objectStore.createIndex("id", "id", { unique: true });
};

const favouriteHome = home => {
    return db.transaction(["favouriteHomes"], "readwrite")
    .objectStore("favouriteHomes")
    .add(home);
}

const getFavouriteHomes = () => {
    if(db) {
        return db.transaction("favouriteHomes")
            .objectStore("favouriteHomes")
            .getAll();}
    else {
        return [];
    }
};

const removeFavouriteHome = home => {
    return db.transaction(["favouriteHomes"], "readwrite")
        .objectStore("favouriteHomes")
        .delete(home.id);
};


module.exports = {
    db: db,
    favouriteHome: favouriteHome,
    getFavouriteHomes: getFavouriteHomes,
    removeFavouriteHome: removeFavouriteHome
}