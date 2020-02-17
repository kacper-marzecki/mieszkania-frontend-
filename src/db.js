window.indexedDB = window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
const DB_NAME = "FS_Mieszkania_DB"

const getRequest = () => window.indexedDB.open("DB_NAME", 1);

