import Web3 from "web3"
import { newKitFromWeb3 } from "@celo/contractkit"
import BigNumber from "bignumber.js"
import ShowzAbi from "../contract/showz.abi.json"
import erc20Abi from "../contract/erc20.abi.json"
import { ERC20_DECIMALS, contractAddress, cUSDContractAddress } from './utils/constants';

let kit
let contract
let showcases = []

// connect to celo
const connectCeloWallet = async function () {
    if (window.celo) {
        notification("⚠️ Please approve this DApp to use it.")
        try {
            await window.celo.enable()
            notificationOff()

            const web3 = new Web3(window.celo)
            kit = newKitFromWeb3(web3)

            const accounts = await kit.web3.eth.getAccounts()
            kit.defaultAccount = accounts[0]

            contract = new kit.web3.eth.Contract(ShowzAbi, contractAddress)
        } catch (error) {
            notification(`⚠️ ${error}.`)
        }
    } else {
        notification("⚠️ Please install the CeloExtensionWallet.")
    }
}

// approve transaction
async function approve(_price) {
    const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

    const result = await cUSDContract.methods
        .approve(contractAddress, _price)
        .send({ from: kit.defaultAccount })
    return result
}

// get user balance
const getBalance = async function () {
    const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
    const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
    document.querySelector("#balance").textContent = `${cUSDBalance} cUSD`
}

// get showcases
const getShowcases = async function () {
    const showcaseLength = await contract.methods.getShowcaseLength().call()
    const _showcases = []
    for (let i = 0; i < showcaseLength; i++) {
        let _showcase = new Promise(async (resolve) => {
            let p = await contract.methods.getShowcases(i).call()
            resolve({
                index: i,
                owner: p[0],
                name: p[1],
                image: p[2],
                description: p[3],
                likes: p[4],
                dislikes: p[5],
            })
        })
        _showcases.push(_showcase)
    }
    showcases = await Promise.all(_showcases)
    renderShowcases()
}

// rending showcase
function renderShowcases() {
    document.getElementById("showcases").innerHTML = ""
    showcases.forEach((_showcase) => {
        const newDiv = document.createElement("div")
        newDiv.className = "col-md-3 mb-4"
        newDiv.innerHTML = showcasesTemplate(_showcase)
        document.getElementById("showcases").appendChild(newDiv)
    })
}

// showcase template
function showcasesTemplate(_showcase) {
    return (`
    <div class="card cus-card shadow border-0">
        <img src="${_showcase.image}" class="card-img-top cover img-card" alt="${_showcase.name}">
        <div class="card-body">
            <h5 class="card-title fw-bold">${_showcase.name.substring(0, 25)}...</h5>
            <p class="card-text">${_showcase.description}</p>
            <div class="d-flex justify-content-between">
                <button id="${_showcase.index}" class="likeBtn btn btn-success">
                    <i class="bi bi-hand-thumbs-up"></i>
                    ${_showcase.likes}
                </button>
                <button id="${_showcase.index}" class="dislikeBtn btn btn-outline-danger">
                    <i class="bi bi-hand-thumbs-down"></i>
                    ${_showcase.dislikes}
                </button>
            </div>
        </div>
    </div>
    `)
}

// like showcase
window.addNewShowcase.addEventListener("click", async () => {
    const _showcase = [
        document.getElementById("showcaseName").value,
        document.getElementById("showcaseImage").value,
        document.getElementById("showcaseDescription").value,
    ]

    notification(`Adding "${_showcase[0]}"...`)

    try {
        await contract.methods
            .addShowcases(..._showcase)
            .send({ from: kit.defaultAccount })
        notification(`You successfully added "${_showcase[0]}".`)
        getShowcases()
        document.getElementById("showcaseImage").value = ""
        document.getElementById("showcaseName").value = ""
        document.getElementById("showcaseDescription").value = ""
    } catch (error) {
        notification(`⚠️ ${error}.`)
    }
})

// like showcase
document.querySelector("#showcases").addEventListener("click", async (e) => {
    if (e.target.className.includes("likeBtn")) {
        const index = e.target.id
        try {
            await contract.methods.likeShowcase(index).send({ from: kit.defaultAccount })
            notification(`🎉 You successfully liked "${showcases[index].name}".`)
            getShowcases()
            getBalance()
        } catch (error) {
            notification(`⚠️ ${error}.`)
        }
    }
    if (e.target.className.includes("dislikeBtn")) {
        const index = e.target.id
        try {
            await contract.methods.dislikeShowcase(index).send({ from: kit.defaultAccount })
            notification(`🎉 You successfully disliked "${showcases[index].name}".`)
            getShowcases()
            getBalance()
        } catch (error) {
            notification(`⚠️ ${error}.`)
        }
    }
})

// notification on
function notification(_text) {
    document.querySelector(".alert").style.display = "block"
    document.querySelector("#notification").textContent = _text
}

// notification off
function notificationOff() {
    document.querySelector(".alert").style.display = "none"
}

// on load screen
window.addEventListener("load", async () => {
    notification("⌛ Loading...");
    await connectCeloWallet();
    await getBalance();
    await getShowcases();
    notificationOff();
});