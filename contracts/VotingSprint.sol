pragma solidity ^ 0.4.18;

import "./Owned.sol";
import "./BalanceFreezer.sol";

contract VotingSprint is Owned, BalanceFreezer {
    
    uint public startDate;                                                              //  Начальная дата спринта
    uint public endDate;                                                                //  Конечная дата спринта
    uint public durationDays;                                                           //  Длительность спринта в днях
    uint public minumumPercentVotesForAccepted;                                         //  Минимальный процент голосов от общего числа голосов для принятия проекта

    mapping(address => bool) public acceptedProjectsMap;                                //  Принятые проекты
    mapping(address => bool) public projectsForVoting;                                  //  Проекты в наличии в спринте
    mapping(address => uint) public projectsVotings;                                    //  Общее количество голосов за каждый проект
    //      projectAddress      investorAddress     tokensAmount      
    mapping(address => mapping( address =>          uint)) projectsInvestorsAmountMap;  //  Взаимосвязь голосов инвесторов и проектов

    uint public totalVotes;                                                             //  Максимальное количество голосов для проекта

    function VotingSprint(uint _durationDays) public {
        require(_durationDays > 0);
        startDate = now;
        durationDays = _durationDays;
        endDate = startDate + durationDays * 1 days;
    }
    //  Добавить проект в спринт
    function addProjectForVoting(address _externalId) public onlyOwner {
        projectsForVoting[_externalId] = true;
    }
    //  Оставить оценку за проект
    function submitVote(address _externalId, uint _value) public {
        //Если значение больше нуля и проект есть в спринте
        require(_value > 0 && projectsForVoting[_externalId]);
        //замораживаем у пользователя токены на определенный срок
        if (this.getFrozenAmount(tx.origin) < _value) {
        this.freeze(_value, durationDays);
        }
        //Добавляем голос пользователя за проект
        projectsInvestorsAmountMap[_externalId][tx.origin] += _value;
        projectsVotings[_externalId] += _value;
        //Проверяем набралось ли достаточное количество голосов для accepted
        if (!acceptedProjectsMap[_externalId] && percent(projectsVotings[_externalId], totalVotes, 2) >= minumumPercentVotesForAccepted) {
            acceptedProjectsMap[_externalId] = true;
        }
    }
    //  Получение статуса проекта на голосовании
    function isAccepted(address _externalId) public onlyOwner returns(bool) {
        //  Проверяем есть ли вообще проект в спринте
        require(projectsForVoting[_externalId]);
        return acceptedProjectsMap[_externalId];
    }
    //  Задаем максимальное число голосов за проект в спринте
    function setTotalVotes(uint _value) public onlyOwner returns(uint) {
        require(_value > 0);
        totalVotes = _value;
        return totalVotes;
    }
    //  Получает процент от числа
    function percent(uint numerator, uint denominator, uint precision) private returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint _numerator = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
  }
}