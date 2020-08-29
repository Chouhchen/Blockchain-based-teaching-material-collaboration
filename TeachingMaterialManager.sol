// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;
import "./ABDKMathQuad.sol";

contract TeachingMaterialManager{
    struct Material{
        address author;
        string name;
        string hash;
        uint[] references;
        bytes8[] proportions;
    }
    Material[] public materials;
    mapping (uint => address) public materialToAuthor;
    mapping (address => uint) ownerMaterialCount;
    event NewMaterial(uint materialId, string name);

    function createMaterial(string calldata name, string calldata hash)
    public returns (uint){
        uint id = materials.length;
        uint[] memory references;
        bytes8[] memory proportions;
        materials.push(Material(
            msg.sender, name, hash, references, proportions));
        materialToAuthor[id] = msg.sender;
        ownerMaterialCount[msg.sender]++;
        emit NewMaterial(id, name);
        return id;
    }

    function deriveMaterial(string calldata name, string calldata hash,
        uint[] calldata ids, bytes8[] calldata proportions)
    public returns (uint){
        uint id = materials.length;
        materials.push(Material(
            msg.sender, name, hash, ids, proportions));
        materialToAuthor[id] = msg.sender;
        ownerMaterialCount[msg.sender]++;
        emit NewMaterial(id, name);
        return id;
    }

    function getMaterial(uint id)
    public view returns (Material memory){
        return materials[id];
    }

    function getProportions(uint materialId) public view
    returns(address[] memory, bytes8[] memory){
        (address[] memory addresses, bytes16[] memory proportions) = _getProportions(materialId);
        bytes8[] memory ret_props = new bytes8[](proportions.length);
        for(uint i = 0; i < ret_props.length; i++){
            ret_props[i] = ABDKMathQuad.toDouble(proportions[i]);
        }
        return (addresses, ret_props);
    }

    function _getProportions(uint materialId) private view
    returns(address[] memory, bytes16[] memory){
        uint initial_array_size = 10;
        uint authors_len = 0;
        uint proportions_len = 0;
        address[] memory authors = new address[](initial_array_size);
        bytes16[] memory proportions = new bytes16[](initial_array_size);

        Material memory mat = getMaterial(materialId);
        bytes16 authorProp = ABDKMathQuad.fromInt(1);
        for(uint i = 0; i < mat.references.length; i++){
            bytes16 prop = ABDKMathQuad.fromDouble(mat.proportions[i]);
            authorProp = ABDKMathQuad.sub(authorProp, prop);
            (address[] memory sauthors, bytes16[] memory sproportions) = _getProportions(mat.references[i]);
            for(uint j = 0; j < sauthors.length; j++){
                address a = sauthors[j];
                bytes16 p = ABDKMathQuad.mul(sproportions[j], prop);
                uint k = 0;
                for(; k < authors.length; k++){
                    if(authors[k] == a) break;
                }
                if(k == authors.length){
                    (authors, authors_len) = address_array_push(authors, authors_len, a);
                    (proportions, proportions_len) = bytes16_array_push(proportions, proportions_len, p);
                } else{
                    proportions[k] = ABDKMathQuad.add(proportions[k], p);
                }
            }
        }
        uint k = 0;
        for(; k < authors.length; k++){
            if(authors[k] == mat.author) break;
        }
        if(k == authors.length){
            (authors, authors_len) = address_array_push(authors, authors_len, mat.author);
            (proportions, proportions_len) = bytes16_array_push(proportions, proportions_len, authorProp);
        } else{
            proportions[k] = ABDKMathQuad.add(proportions[k], authorProp);
        }
        return (address_array_trim(authors, authors_len),
            bytes16_array_trim(proportions, proportions_len));
    }

    function address_array_push(address[] memory array, uint size, address element)
    private pure returns(address[] memory, uint){
        if(array.length == size){
            address[] memory newarray = new address[](array.length * 2 + 1);
            for(uint i = 0; i < array.length; i++){
                newarray[i] = array[i];
            }
            newarray[array.length] = element;
            return (newarray, size + 1);
        }
        array[size] = element;
        return (array, size + 1);
    }

    function address_array_trim(address[] memory array, uint size)
    private pure returns(address[] memory){
        if(array.length == size){
            return array;
        }
        address[] memory newarray = new address[](size);
        for(uint i = 0; i < size; i++){
            newarray[i] = array[i];
        }
        return newarray;
    }

    function bytes16_array_push(bytes16[] memory array, uint size, bytes16 element)
    private pure returns(bytes16[] memory, uint){
        if(array.length == size){
            bytes16[] memory newarray = new bytes16[](array.length * 2 + 1);
            for(uint i = 0; i < array.length; i++){
                newarray[i] = array[i];
            }
            newarray[array.length] = element;
            return (newarray, size + 1);
        }
        array[size] = element;
        return (array, size + 1);
    }

    function bytes16_array_trim(bytes16[] memory array, uint size)
    private pure returns(bytes16[] memory){
        if(array.length == size){
            return array;
        }
        bytes16[] memory newarray = new bytes16[](size);
        for(uint i = 0; i < size; i++){
            newarray[i] = array[i];
        }
        return newarray;
    }
}