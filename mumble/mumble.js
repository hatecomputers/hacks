const crypto = require('crypto')
const axios = require('axios')
const fs = require('fs')
// const proxyAgent = require('https-proxy-agent');

// axios = axios.create(proxyAgent({
//     host: '127.0.0.1',
//     port: '8080'
// }))

const SECRET = 'whitetelevisionbulbelectionroofhorseflying'

const BUMBLE_URL =  'https://bumble.com';
const BUMBLE_API_PATH = 'mwebapi.phtml';
const BUMBLE_API_METHODS = {
    'get_user_list': 'SERVER_GET_USER_LIST',
    'get_providers': 'SERVER_GET_EXTERNAL_PROVIDERS',
    'get_user': 'SERVER_GET_USER',
    'get_user_list': 'SERVER_GET_USER_LIST',
    'swipe': 'SERVER_ENCOUNTERS_VOTE',
    'chat_info': 'SERVER_OPEN_CHAT',
    'get_users': 'SERVER_GET_ENCOUNTERS',
}

const defaultHeaders = {
    'Cookie': 'session=<session_cookie_goes_here>',
    'Content-Type': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:101.0) Gecko/20100101 Firefox/101.0',
    'X-Use-Session-Cookie': '1'
}

const args = process.argv;

const combine = (body, signature) => `${body}${signature}`

const getHash = valueCombined => crypto.createHash('md5').update(valueCombined).digest('hex')

const request = async (url, body, headers) => { 
   return await axios
        .post(url, body, { headers })
}

const getUsers = results => {
    return results.map(unparsedUser => {
        const { user } = unparsedUser;
        return { id: user.user_id, user }
    })
}

const allUsers = require('./users.json');

const getRequestSetup = (method, bodyString) => {
    const url = `${BUMBLE_URL}/${BUMBLE_API_PATH}?${BUMBLE_API_METHODS[method]}`;
    const requestId = getHash(combine(bodyString, SECRET))
    const headers = Object.assign({}, defaultHeaders, {'X-Pingback': requestId})
    const body = JSON.parse(bodyString)
    
    return { url, headers, body }
}

const mineUsers = async () => {
    const bodyString = `{"$gpb":"badoo.bma.BadooMessage","body":[{"message_type":81,"server_get_encounters":{"number":30,"context":1,"user_field_filter":{"projection":[210,370,200,230,490,540,530,560,291,732,890,930,662,570,380,493,1140,1150,1160,1161],"request_albums":[{"album_type":7},{"album_type":12,"external_provider":12,"count":8}],"game_mode":0,"request_music_services":{"top_artists_limit":8,"supported_services":[29],"preview_image_size":{"width":120,"height":120}}}}}],"message_id":7,"message_type":81,"version":1,"is_background":false}` 
    const { url, headers, body } = getRequestSetup('get_users', bodyString);
    
    try {
        const response = await request(url, body, headers)
        console.log(response.data.body[0])
        const results = response.data.body[0].client_encounters.results
        const users = getUsers(results)

        users.reduce((acc, { id, user }) => {
            if (! acc[id]) {
                console.log(`New id being added ${id}...`)
                acc[id] = user;
            }
            return acc
        }, allUsers)

        fs.writeFile('./users.json', JSON.stringify(allUsers), (err) => {
            if (err) throw err;

            console.log('File has been written.')
        })
    
    } catch (e) {
        console.log(e)
    }
}

const voteToAll = async () => {
    for (const userId in allUsers) {
       const bodyString = `{"$gpb":"badoo.bma.BadooMessage","body":[{"message_type":80,"server_encounters_vote":{"person_id":"<person_id>","vote":3,"vote_source":1,"game_mode":0}}],"message_id":21,"message_type":80,"version":1,"is_background":false}` 
       const bodyStringWithId = bodyString.replace('<person_id>', userId)
       const { url, headers, body } = getRequestSetup('swipe', bodyStringWithId);

        try {
            const response = await request(url, body, headers)
            const clientVoteResponse = response.data.body[0].client_vote_response
            
            if(response.status === 200 && clientVoteResponse) {
                console.log(`Vote ${userId} has been computed...`)
            }
        } catch (e) {
            console.log(e)
        }
    }
}

if (args[2] === '--vote') voteToAll()
else if (args[2] === '--mine') mineUsers()
else throw Error(`Option not recognized.\nTry using .${args[1]} --vote or .${args[1]} --mine.`)
