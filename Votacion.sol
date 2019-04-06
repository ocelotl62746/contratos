pragma solidity ^0.5.6;

contract managed {
    address admin;
    constructor () public{
        admin = msg.sender;
    }
    modifier onlyAdmin(){
        require(admin == msg.sender);
        _;
    }
    function kill() private onlyAdmin{
        selfdestruct(msg.sender);
    }
}

contract Votacion is managed{
    bytes32[] Candidatos;
    enum estadoEleccion {INACTIVA, ACTIVA, FINALIZADA}
    struct Votante {
        bool voto_emitido;
        uint opcion_elegida;
        bool votante_autorizado;
    }
    address administrador;
    struct Config {
      uint inicio;
      uint duracion;
      estadoEleccion estatus;
    }
    mapping(address => Votante) votantes;
    mapping(uint => uint) votos_recibidos;
    Config eleccion;

    constructor (bytes32[] memory opciones, uint _duracion) public {
        administrador = msg.sender;
        votantes[administrador].votante_autorizado = true;
        eleccion.duracion = _duracion;
        eleccion.estatus = estadoEleccion.INACTIVA;
        Candidatos = opciones;
    }

    function autorizarVotante(address votante) public onlyAdmin{
        require(eleccion.estatus == estadoEleccion.INACTIVA);
        require(!votantes[votante].votante_autorizado);
        votantes[votante].votante_autorizado = true;
    }

    function iniciarEleccion() public onlyAdmin{
        require(eleccion.estatus == estadoEleccion.INACTIVA);
        eleccion.inicio = now;
        eleccion.estatus = estadoEleccion.ACTIVA;
    }

    function votar(uint candidato) public {
        //require (inicio_eleccion > 0);
        require(eleccion.estatus == estadoEleccion.ACTIVA);
        require(now < finEleccion());
        Votante storage elector = votantes[msg.sender];
        require(elector.votante_autorizado);
        require(!elector.voto_emitido);
        require(candidato<Candidatos.length);
        elector.voto_emitido = true;
        elector.opcion_elegida = candidato;
        votos_recibidos[candidato] += 1;
    }

    function votosObtenidos(uint candidato) view public
            returns (uint votos_candidato)
    {
      require(eleccion.estatus != estadoEleccion.ACTIVA);
      votos_candidato = votos_recibidos[candidato];
    }

    function horaActual() view public
            returns (uint _now)
    {
        _now = now;
    }

    function inicioEleccion() view public
            returns (uint)
    {
        require(eleccion.estatus != estadoEleccion.INACTIVA);
        return eleccion.inicio;
    }

    function finEleccion() view public
            returns (uint)
    {
        require(eleccion.estatus != estadoEleccion.INACTIVA);
        return eleccion.inicio + eleccion.duracion;
    }

    function obtenerCandidatos() public view returns (bytes32[] memory) {
        return Candidatos;
    }

    function generarResultados() public onlyAdmin{
        require(now > eleccion.inicio + eleccion.duracion);
        require(eleccion.estatus == estadoEleccion.ACTIVA);
        eleccion.estatus = estadoEleccion.FINALIZADA;
    }

    function estatusEleccion() view public returns (uint){
      return uint(eleccion.estatus);
    }
}
