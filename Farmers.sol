pragma solidity^0.4.20;

import "./Exchange.sol";
import "./Factories.sol";

contract Farmers{
    //This enum represents farmer's status
    enum Status{ Unregister, Registered, Banned}

    Factories factories;
    Exchange exchange;

    //This struct represents identity of farmer
    //name   : farmer's name
    //wallet : farmer's address
    //id     : farmer's id that is acquire when register
    //farmArea: estate that farmer had owned for growing store in "squre meter"
    //usedFarmArea: part of farmer's estate that currently use for growing.
    //farmAddress : Real address of farm that farmer owned;
    //farmIdRecord: Array for record all farm Id
    struct Farmer{
        string name;
        address wallet;
        bytes32 id;
        uint farmArea;
        uint usedFarmArea;
        string farmAddress;
        bytes32[] farmIdRecord;
    }

    //This struct represents farmer's growing record including growing and harvested also as fertilize's log.
    //owner      : Owner of this farm
    //usedArea   : Amount of estate that use for this growing
    //plantGrow  : Name of crop or plant that grow
    //startDate  : Timestamp when start to grow crop
    //harvestDate: Timestamp when harvest crop
    //harvestAmount: Weight of crop that had harvested
    //fertLog    : Fertilize's record
    struct Farm{
        address owner;
        uint usedArea;
        string plantGrow;
        uint startDate;
        uint harvestDate;
        uint havestamount;
        FertilizerLog[] fertLog;
        //bytes32 certificate;
    }

    //This struct represents templete of fertilize
    //fertilizerId : Fertilizer Id from factory
    //produceTag: Fertilizer Tag from factory
    //amount    : Amount of fertilizer that used in kg.
    //date      : Timestamp when apply fertilizer
    struct FertilizerLog{
        bytes32 fertilizerId;
        bytes32 produceTag;
        uint amount;
        uint date;
    }
    //This mapping represents farmerStatus by map address to status
    mapping(address => Status) farmerStatus;

    //This mapping represents farmer identity by map address to farmer information
    mapping(address => Farmer) farmerDatabase;

    //This mapping represents farm information by map farm tag to it's information
    mapping(bytes32 => Farm) farmTag;

    //Constructor of this contract that require 2 args that are contract address of factories and exchange contract.
    function Farmers(address FACTORIES_CONTRACT, address EXCHANGE_CONTRACT) public {
        factories = Factories(FACTORIES_CONTRACT);
        exchange = Exchange(EXCHANGE_CONTRACT);
    }

    //This modifier use to allow only owner to execute function
    modifier owner(){
        require(msg.sender == farmerDatabase[msg.sender].wallet);
        _;
    }
    //This modifier use to allow only planted farm to execute function
    modifier planting(bytes32 _farmId){
        require(farmTag[_farmId].startDate > 0);
        require(farmTag[_farmId].harvestDate == 0);
        _;
    }

    //This function use to register an unregister farmer, it's require farmer's name,
    //farm area that farmer own, farmer's farm address.
    function register(string _name, uint _farmArea, string _farmAddress) public{
        require(farmerStatus[msg.sender] == Status.Unregister);
        farmerDatabase[msg.sender].wallet = msg.sender;
        farmerStatus[msg.sender] = Status.Registered;
        farmerDatabase[msg.sender].name = _name;
        farmerDatabase[msg.sender].farmArea = _farmArea;
        farmerDatabase[msg.sender].farmAddress = _farmAddress;
        farmerDatabase[msg.sender].id = keccak256(_name,_farmAddress,msg.sender);
    }

    //this function use to plant on farm, it's require plant's name and amount of farm area that use.
    function plant(string _plantGrow, uint _useArea)public owner {
        require(getFarmArea(msg.sender) >= getUsedFarmArea(msg.sender) + _useArea);
        farmerDatabase[msg.sender].usedFarmArea = getUsedFarmArea(msg.sender) + _useArea;
        bytes32 _farmId = keccak256(_plantGrow,msg.sender,now);
        farmTag[_farmId].owner = msg.sender;
        farmTag[_farmId].usedArea = _useArea;
        farmTag[_farmId].plantGrow = _plantGrow;
        farmTag[_farmId].startDate = now;
        farmerDatabase[msg.sender].farmIdRecord.push(_farmId);
    }

    //
    function fertilize(bytes32 _farmId, bytes32 _fertilizerId, bytes32 _produceTag, uint _amount)public owner planting(_farmId) {
        //usedFert (Factory)
        //apply
        FertilizerLog memory tmp;
        tmp.fertilizerId = _fertilizerId;
        tmp.produceTag = _produceTag;
        tmp.amount = _amount;
        tmp.date = now;
        farmTag[_farmId].fertLog.push(tmp);
    }

    //this function use to havest a ready one, it's require farmId and harvested amount(in kg.).
    function havest(bytes32 _farmId,uint _harvestAmount)public owner planting(_farmId) {
        farmerDatabase[msg.sender].usedFarmArea = getUsedFarmArea(msg.sender) - farmTag[_farmId].usedArea;
        farmTag[_farmId].harvestDate = now;
        farmTag[_farmId].havestamount = _harvestAmount;
        exchange.addProduct(_farmId,_harvestAmount,this);
    }

    //this function use to buy Fertilizer from FACTORIES_CONTRACT,
    //it's need to fill fertilizerId with it's tag and buying amount;
    function buyFertilizer(bytes32 _fertilizerId, bytes32 _produceTag, uint _buyAmount)public payable owner {
        //From factor
        require(msg.value == factories.getPrice(_produceTag)*_buyAmount);
        factories.sellFert(_fertilizerId,_produceTag,_buyAmount);
        factories.getWallet(_produceTag).transfer(msg.value);
    }

    //this function use to expand farm, it's require the expanded area.
    function expandFarm(uint _expandArea)public owner {
        farmerDatabase[msg.sender].farmArea = getFarmArea(msg.sender) + _expandArea;
    }

    //this function use to expand farm, it's require the reduced area.
    function reduceFarm(uint _reduceArea)public owner {
        farmerDatabase[msg.sender].farmArea = getFarmArea(msg.sender) - _reduceArea;
    }

    //Getter&Setter
    function getStatus(address farmerAddr)public view returns(Status) {return farmerStatus[farmerAddr];}
    function getName(address farmerAddr)public view returns(string) {return farmerDatabase[farmerAddr].name;}
    function getWallet(address farmerAddr)public view returns(address) {return farmerDatabase[farmerAddr].wallet;}
    function getFarmArea(address farmerAddr)public view returns(uint){return farmerDatabase[farmerAddr].farmArea;}
    function getUsedFarmArea(address farmerAddr)public view returns(uint){return farmerDatabase[farmerAddr].usedFarmArea;}
    function getFarmAddress(address farmerAddr)public view returns(string) {return farmerDatabase[farmerAddr].farmAddress;}
    function getId(address farmerAddr)public view returns(bytes32) {return farmerDatabase[farmerAddr].id;}
    function getFarmId(address farmerAddr,uint i)public view returns(bytes32) {return farmerDatabase[farmerAddr].farmIdRecord[i];}
}

//mock up
