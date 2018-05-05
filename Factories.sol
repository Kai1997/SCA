pragma solidity^0.4.20;

contract Factories{
    //This enum represents farmer's status
    enum Status{Unregister, Registered, Banned}

    //This struct represents identity of factory
    //name   : factory's name
    //wallet : factory's address
    //id     : factory's id that is acquire when register
    //facAddress    : Real address of factory
    //fertilizerId  : Array for record all factory product
    //fertilizerInfo: Detail of fertilizerId
    //fertilizerLot : mapping that map product to it's produced lot.
    struct Factory{
        string name;
        address wallet;
        bytes32 id;
        string facAddress;
        bytes32[] fertilizerId;
        mapping(bytes32 => FertilizerInfo) fertilizerInfo;
        mapping(bytes32 => bytes32[])fertilizerLot;
    }

    //This struct represents infomation of product(fertilizer)
    //fertilizerId: Product's id
    //npk         : Product npk;
    //detail      : Other product detail
    struct FertilizerInfo{
        bytes32 fertilizerId;
        int[3] npk;
        string detail;
    }
    
    //This struct represents fertilizerLot status
    //ownerWallet : address of the owner of this product lot
    //date        : produced time
    //price       : price of this lot 
    //producedMax : amount of fertilizer that produced
    //producedUsed: Array for record all factory product
    //producedSold: Detail of fertilizerId
    //holder      :
    struct FertilizerSupply{
        address ownerWallet;
        uint date;
        uint price;
        uint producedMax;
        uint producedUsed;
        uint producedSold;
        mapping(address => uint)holder;
    }

    //This mapping represents factoryStatus by map address to status
    mapping(address => Status) factoryStatus;
    
    //This mapping represents factory identity by map address to factory information
    mapping(address => Factory) factoryDatabase;
    
    //This mappin represents all produced lot by map lot's id to it's information
    mapping(bytes32 => FertilizerSupply) fertilizerTagSupply;
    
    //Constructure of this contract for now it's do nothing
    function Factories()public{

    }
    
    //This modifier use to allow only owner to execute function
    modifier owner(){
        require(msg.sender == factoryDatabase[msg.sender].wallet);
        _;
    }
    //This function use to register an unregister factory, it's require factory's name and it's located address.
    function register(string _name, string _facAddress)public{
        require(factoryStatus[msg.sender] == Status.Unregister);
        factoryDatabase[msg.sender].wallet = msg.sender;
        factoryStatus[msg.sender] = Status.Registered;
        factoryDatabase[msg.sender].name = _name;
        factoryDatabase[msg.sender].facAddress = _facAddress;
        factoryDatabase[msg.sender].id = keccak256(_name,_facAddress,msg.sender);

    }

    //This function use to create new product(fertilizer), it's require some information that fertilizerInfo need. 
    function newFertLine(bytes32 _fertilizerId, int[3] _npk, string _description)public owner{
        require(!isFertExist(_fertilizerId));
        factoryDatabase[msg.sender].fertilizerId.push(_fertilizerId);
        factoryDatabase[msg.sender].fertilizerInfo[_fertilizerId].fertilizerId = _fertilizerId;
        factoryDatabase[msg.sender].fertilizerInfo[_fertilizerId].npk = _npk;
        factoryDatabase[msg.sender].fertilizerInfo[_fertilizerId].detail =_description;
    }

    //This function use to produce a new lot of existing product(fertilizer).
    function produceLot(bytes32 _fertilizerId, uint _price, uint _produceMax)public owner{
        require(isFertExist(_fertilizerId));
        bytes32 produceTag = keccak256(_fertilizerId,msg.sender,now);//if produce same product at same time
        factoryDatabase[msg.sender].fertilizerLot[_fertilizerId].push(produceTag);
        fertilizerTagSupply[produceTag].ownerWallet = msg.sender;
        fertilizerTagSupply[produceTag].date = now;
        fertilizerTagSupply[produceTag].price = _price;
        fertilizerTagSupply[produceTag].producedMax = _produceMax;
    }

    //This function use to sell fertilizer to farmer. 
    function sellFert(bytes32 _fertilizerId, bytes32 _produceTag, uint _buyAmount)public{
        require(isFertExist(_fertilizerId));
        require(isFertTagExist(_fertilizerId,_produceTag));
        require(fertilizerTagSupply[_produceTag].producedSold + _buyAmount <= fertilizerTagSupply[_produceTag].producedMax);
        fertilizerTagSupply[_produceTag].holder[msg.sender] += _buyAmount;
        fertilizerTagSupply[_produceTag].producedSold += _buyAmount;
    }

    //This function use when farmer apply fertilizer on their farm
    function applyFert(bytes32 _fertilizerId, bytes32 _produceTag, uint _useAmount)public{
        require(isFertExist(_fertilizerId));
        require(isFertTagExist(_fertilizerId,_produceTag));
        require(fertilizerTagSupply[_produceTag].producedUsed + _useAmount <= fertilizerTagSupply[_produceTag].producedSold);
        fertilizerTagSupply[_produceTag].holder[msg.sender] -= _useAmount;
        fertilizerTagSupply[_produceTag].producedUsed += _useAmount;
    }


    //Getter
    function getPrice(bytes32 _produceTag)public view returns(uint){
        return fertilizerTagSupply[_produceTag].price;
    }
    function getWallet(bytes32 _produceTag)public view returns(address){
        return fertilizerTagSupply[_produceTag].ownerWallet;
    }

    //Check if fertilizer exist or not;
    function isFertExist(bytes32 _fertilizerId)private view returns(bool){
        for(uint i=0; i< factoryDatabase[msg.sender].fertilizerId.length; i++){
            if (factoryDatabase[msg.sender].fertilizerId[i] == _fertilizerId){
                return true;
            }
        }
        return false;
    }
    //Check if fertilizer lot exist or not
    function isFertTagExist(bytes32 _fertilizerId, bytes32 _produceTag)private view returns(bool){
        for(uint i=0; i< factoryDatabase[msg.sender].fertilizerLot[_fertilizerId].length; i++){
            if (factoryDatabase[msg.sender].fertilizerLot[_fertilizerId][i] == _produceTag){
                return true;
            }
        }
        return false;
    }
}
