const { expect } = require("chai");
const { ethers } = require("@nomiclabs/buidler");



describe("Deployment", function() {

    let Brain;
    let UcropToken;
    
    let admin; //owner of brain, token
    
    beforeEach(async function() {
        [admin, addr1, addr2] = await ethers.getSigners();
        brainFactory = await ethers.getContractFactory("Brain", admin);
        Brain = await brainFactory.deploy();
        await Brain.deployed();
        
        TokenFactory = await ethers.getContractFactory("UcropToken", admin);
        UcropToken = await TokenFactory.deploy();
        await UcropToken.deployed();

        await UcropToken.connect(admin).setBrainAddress(await Brain.address);
        await Brain.connect(admin).setUcropTokenAddress(await UcropToken.address);
    });

    describe("Check common parameters", function () {
        it("admin should be owner of Token and Brain", async function () {
            expect(await Brain.owner()).to.be.equal(await admin.getAddress());
            expect(await UcropToken.owner()).to.be.equal(await admin.getAddress());
        });
        it("Token should know BrainAddress", async function() {
            expect(await UcropToken.BrainAddress()).to.be.equal(await Brain.address);
        });
        it("Brain should know UcropTokenAddress", async function() {
            expect(await Brain.ucropTokenAddress()).to.be.equal(await UcropToken.address);
        });
    });
    describe("Check CDP opening", function (){
        const valueToSend = 200;
            it("check CDP opening after sending Ether to Token", async function() {
                //[addr1] = await ethers.getSigners();
                const previousCDPcount = await Brain.connect(addr1).getContractCount()
                await expect(await addr1.sendTransaction({to: UcropToken.address, value: valueToSend})).to.changeBalance(UcropToken,valueToSend);
                expect(await Brain.connect(addr1).getContractCount()).to.be.equal(previousCDPcount+1);
                console.log("\tInitially there were " + previousCDPcount+ " CDPs. And now we have "+ await Brain.connect(addr1).getContractCount() + " CDPs.");
                Addr1Balance = await UcropToken.connect(addr1).balanceOf(addr1.getAddress());
                expect(Addr1Balance).to.be.equal(valueToSend / (await UcropToken.getRate()));
                console.log("\tAddr1 balance now: " + Addr1Balance.toString());
            });         
    //ethers.utils.parseEther("1.0")
        it("check CDP closing by its holder", async function() {
            await addr1.sendTransaction({to: UcropToken.address, value: valueToSend});
            Addr1Balance = await UcropToken.connect(addr1).balanceOf(addr1.getAddress());
            const previousCDPcount = await Brain.connect(addr1).getContractCount()
            const addr1CDPAddress = await Brain.contracts(0);
            SuccessCDPClosing = await UcropToken.connect(addr1).StartClosingCDP(addr1CDPAddress, Addr1Balance);
            console.log("\tInitially there were " + previousCDPcount+ " CDPs. And now we have "+ await Brain.connect(addr1).getContractCount() + " CDPs.");
            
        });
        it("check CDP closing by any person (auction was not held)", async function() {
            await addr1.sendTransaction({to: UcropToken.address, value: valueToSend});
            await addr2.sendTransaction({to: UcropToken.address, value: valueToSend});
            Addr1Balance = await UcropToken.balanceOf(addr1.getAddress());
            Addr2Balance = await UcropToken.balanceOf(addr2.getAddress());
            const previousCDPcount = await Brain.connect(addr1).getContractCount();
            const addr1CDPAddress = await Brain.contracts(0);

            await expect(
                UcropToken.connect(addr2).StartClosingCDP(addr1CDPAddress, Addr1Balance)
            ).to.be.revertedWith("только владелец CDP может закрыть CDP");
            console.log("\tInitially there were " + previousCDPcount+ " CDPs. And now we have "+ await Brain.connect(addr1).getContractCount() + " CDPs.");
        });

        it("check CDP closing by any person (auction was held)", async function() {
            await addr1.sendTransaction({to: UcropToken.address, value: valueToSend});
            await addr2.sendTransaction({to: UcropToken.address, value: valueToSend});
            Addr1Balance = await UcropToken.balanceOf(addr1.getAddress());
            Addr2Balance = await UcropToken.balanceOf(addr2.getAddress());
            const previousCDPcount = await Brain.connect(addr1).getContractCount();
            const addr1CDPAddress = await Brain.contracts(0);
            
            await Brain.connect(admin).broadcastRate(74,2);
            UcropToken.connect(addr2).StartClosingCDP(addr1CDPAddress, Addr1Balance)
            console.log("\tInitially there were " + previousCDPcount+ " CDPs. And now we have "+ await Brain.connect(addr1).getContractCount() + " CDPs.");
            
        });
    });
        
    


});