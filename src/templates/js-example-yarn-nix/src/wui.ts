import _ from 'lodash';
let message: string = 'Hello World';
console.log(message + _.join([' ', 'a', 'b', 'c'], '~'));
