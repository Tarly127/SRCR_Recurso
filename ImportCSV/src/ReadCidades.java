import java.io.*;
import java.util.*;


class Cidade{
    public int ID;
    public int dist;
    public int is_capital;
    public float x, y;

    public Cidade(int ID, int dist, float x, float y, int is_capital){
        this.ID = ID;
        this.dist = dist;
        this.x = x;
        this.y = y;
        this.is_capital = is_capital;
    }
}

class Aresta{
    public int inicio;
    public int fim;
    public double distance;

    public Aresta(int inicio, int fim, double distance){
        this.inicio = inicio;
        this.fim = fim;
        this.distance = distance;
    }

    public boolean equals(Object o){
        if(o == null) return false;
        Aresta a = (Aresta)o;
        return this.inicio == a.inicio
                && this.fim == a.fim
                && this.distance == a.distance;
    }

    public String toString(){
        return "aresta(" + this.inicio + ',' + this.fim + ',' + this.distance + ")";
    }
}

public class ReadCidades {

    //Tamanho do predicado cidade
    private static final int CIDADE_SIZE = 8;
    //Map das cidades
    private static Map<Integer, Cidade> cidades = new HashMap<>();
    //Mao com as arestas de cada cidade
    private static Map<Integer, List<Aresta>> arestas = new HashMap<>();
    //Map da relação Id distrito com a cidade capital
    private static Map<Integer, Cidade> capitais_distritais = new HashMap<>();
    //Map com as cidades agrupadas por distritos
    private static Map<Integer, List<Integer>> distritos = new HashMap<>();
    //Lista das adjacências dos distritos
    private static final Integer[][] adj_dists = {
            {2},                 //Viana do Castelo
            {1,3,7},             //Braga
            {2,7,6,4},           //Vila Real
            {3,5,6},             //Bragança
            {4,6,9,10},          //Guarda
            {3,5,9,8,7},         //Viseu
            {2,3,6,8},           //Porto
            {6,7,9},             //Aveiro
            {5,6,8,10,11},       //Coimbra
            {5,9,11,12,13},      //Castelo Branco
            {9,10,12,14},        //Leiria
            {10,11,13,14,15,16}, //Santarém
            {10,12,16},          //Portalegre
            {11,12,15},          //Lisboa
            {12,14,16,17},       //Setúbal
            {12,13,15,17},       //Évora
            {15,16,18},          //Beja
            {17}                 //Faro
    };

    //Escrever em ficheiro

    private static void write_grafo(FileWriter out) throws IOException{
        for(Map.Entry<Integer, List<Aresta>> e : arestas.entrySet()){
            for(Aresta a : e.getValue()){
                out.write(a.toString() + ".\n");
            }
        }
    }

    private static void write_distritos(FileWriter out) throws IOException{
        for(Map.Entry<Integer, List<Integer>> e : distritos.entrySet()){
            StringBuilder sb = new StringBuilder();

            sb.append("distrito(").append(e.getKey()).append(",[");
            int size = e.getValue().size();
            int it = 0;

            for(Integer i : e.getValue()){
                if(it != size-1){
                    sb.append(i);
                    sb.append(",");
                    it++;
                }
                else {
                    sb.append(i);
                }
            }

            sb.append("]).\n");
            out.write(sb.toString());
        }
    }


    //Gerar as arestas

    private static void write_arestas_dists(){
        for(Cidade c : capitais_distritais.values()){
            write_aresta_dist(c);
        }
    }

    private static void write_aresta_dist(Cidade cap){
        Integer[] dists_adj = adj_dists[cap.dist-1];
        List<Aresta> lst_a;

        if(arestas.containsKey(cap.ID)){
            //Sacar a lista de adjs da capital
            lst_a = arestas.get(cap.ID);
        }
        else{
            //Se não existir, inicializar a nova lista
            lst_a = new ArrayList<>();
        }
        //Percorrer as capitais que fazem fronteira
        for(Integer dist_ao_lado : dists_adj){
            //Obter a capital distrital
            Cidade aux = capitais_distritais.get(dist_ao_lado);
            double distance = distance(cap.x, cap.y, aux.x, aux.y);
            //Adiciono a aresta cap -> aux à lista
            lst_a.add(new Aresta(cap.ID, aux.ID, distance));
        }
        //Colocar a nova lista no map de arestas
        arestas.put(cap.ID, lst_a);
    }

    private static void write_arestas_cids_dist(){
        //Percorrer o map de distritos
        for(Map.Entry<Integer, List<Integer>> e1 : distritos.entrySet()){

            //Obter a cidade capital distrital e a lista de arestas
            Cidade cap_dist = capitais_distritais.get(e1.getKey());

            List<Aresta> cap_arestas = arestas.get(cap_dist.ID);
            if(cap_arestas == null) cap_arestas = new ArrayList<>();

            //Percorrer as cidades do distritos
            for(Integer i : e1.getValue()){
                if(cap_dist.ID != i){
                    Cidade aux = cidades.get(i);
                    double distance = distance(aux.x, aux.y, cap_dist.x, cap_dist.y);

                    List<Aresta> cid_arestas = arestas.get(aux.ID);
                    if(cid_arestas == null) cid_arestas = new ArrayList<>();

                    //Escrever as arestas
                    //cap -> cidade
                    cap_arestas.add(new Aresta(cap_dist.ID, aux.ID, distance));
                    //cidade -> cid
                    cid_arestas.add(new Aresta(aux.ID, cap_dist.ID, distance));

                    //Guardar o vetor de arestas da cidade
                    arestas.put(aux.ID, cid_arestas);
                }
            }

            //Guardar as arestas da capital
            arestas.put(cap_dist.ID, cap_arestas);
        }
    }

    private static void write_rand_arestas(int min, int max){
        //Percorrer as cidades
        for(Map.Entry<Integer, Cidade> e1 : cidades.entrySet()){
            Cidade cid = e1.getValue();

            //Verificar se não estamos na capital distrital
            if(cid.is_capital == 0){
                Integer[] dists_adj = adj_dists[cid.dist-1];
                List<Aresta> cid_arestas = arestas.get(cid.ID);

                //Percorrer cada um dos distritos que fazem fronteira com o distrito da cidade onde estamos
                for(Integer dist_ao_lado : dists_adj){

                    //Gerar um número aleatório de ligações que vamos fazer a cidades do distrito
                    Random rand = new Random();
                    int number_of_arestas = rand.nextInt(max) + min ;

                    //Obter a lista de cidades do distrito
                    List<Integer> cids_dist_ao_lado = distritos.get(dist_ao_lado);

                    //Randomize a lista para podermos escolher arestas aleatórias para criar.
                    Collections.shuffle(cids_dist_ao_lado);

                    //Percorrer a lista
                    for(int i = 0; i < number_of_arestas && i < cids_dist_ao_lado.size(); i++){

                        Cidade n_vertice = cidades.get(cids_dist_ao_lado.get(i));

                        //Se não existe aresta cid - n_vertice, vamos criar
                        if(!existe_aresta(cid, n_vertice)){

                            //Preparar a criação das duas arestas
                            double distance = distance(cid.x, cid.y, n_vertice.x, n_vertice.y);
                            List<Aresta> n_vertice_arestas = arestas.get(n_vertice.ID);

                            //Criar as duas arestas
                            n_vertice_arestas.add(new Aresta(n_vertice.ID, cid.ID, distance));
                            cid_arestas.add(new Aresta(cid.ID, n_vertice.ID, distance));

                            //Colocar o array modificado das arestas no n_vertice de volta no Map
                            arestas.put(n_vertice.ID, n_vertice_arestas);
                        }
                        //Se existe, vamos ignorar e diminuir o número de arestas que vamos criar para cid, para não termos mais ligações do que as que queremos.
                        else{
                            number_of_arestas--;
                        }
                    }
                }

                //Fazer agora o mesmo para cidades no mesmo distrito

                //Obter a lista de cidades no mesmo distrito
                List<Integer> cids_mesmo_dist = distritos.get(cid.dist);

                //Randomize um número de ligações e a lista em si.
                Collections.shuffle(cids_mesmo_dist);
                Random rand = new Random();
                int number_of_arestas = rand.nextInt(max) + min;

                //Percorrer a lista para fazer as arestas
                for(int i = 0; i < number_of_arestas && i < cids_mesmo_dist.size(); i++){
                    Cidade n_vertice = cidades.get(cids_mesmo_dist.get(i));

                        //Se não existe aresta cid - n_vertice, vamos criar, e se o n_vertice NÃO for cid
                        if(!existe_aresta(cid, n_vertice) && cid.ID != n_vertice.ID){

                            //Preparar a criação das duas arestas
                            double distance = distance(cid.x, cid.y, n_vertice.x, n_vertice.y);
                            List<Aresta> n_vertice_arestas = arestas.get(n_vertice.ID);

                            //Criar as duas arestas
                            n_vertice_arestas.add(new Aresta(n_vertice.ID, cid.ID, distance));
                            cid_arestas.add(new Aresta(cid.ID, n_vertice.ID, distance));

                            //Colocar o array modificado das arestas no n_vertice de volta no Map
                            arestas.put(n_vertice.ID, n_vertice_arestas);
                        }
                        //Se existe, vamos ignorar e diminuir o número de arestas que vamos criar para cid, para não termos mais ligações do que as que queremos.
                        else{
                            number_of_arestas--;
                        }
                }

                //Por fim, guardar a Lista de arestas novas desta cidade
                arestas.put(cid.ID, cid_arestas);
            }
        }
    }



    //Auxiliares

    private static double distance(float x1, float y1, float x2, float y2){
        double R = 6371e3;
        double psi1 = x1 * Math.PI/180;
        double psi2 = x2 * Math.PI/180;
        double delta_psi = (x2 - x1) * Math.PI/180;
        double delta_lambda = (y2 - y1) * Math.PI/180;

        double a = Math.pow(Math.sin(delta_psi/2), 2) * Math.cos(psi1) * Math.cos(psi2) * Math.pow(Math.sin(delta_lambda/2), 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        return c * R;
    }

    private static boolean existe_aresta(Cidade a, Cidade b){

        double distance = distance(a.x, a.y, b.x, b.y);
        return arestas.get(a.ID).contains(new Aresta(a.ID, b.ID, distance)) || arestas.get(b.ID).contains(new Aresta(b.ID, a.ID, distance));
    }

    private static int switch_distrito(String d){
        if(d.compareTo("viana_do_castelo") == 0) return 1;
        if(d.compareTo("braga") == 0)            return 2;
        if(d.compareTo("vila_real") == 0)        return 3;
        if(d.compareTo("braganca") == 0)         return 4;
        if(d.compareTo("guarda") == 0)           return 5;
        if(d.compareTo("viseu") == 0)            return 6;
        if(d.compareTo("porto") == 0)            return 7;
        if(d.compareTo("aveiro") == 0)           return 8;
        if(d.compareTo("coimbra") == 0)          return 9;
        if(d.compareTo("castelo_branco") == 0)   return 10;
        if(d.compareTo("leiria") == 0)           return 11;
        if(d.compareTo("santarem") == 0)         return 12;
        if(d.compareTo("portalegre") == 0)       return 13;
        if(d.compareTo("lisboa") == 0)           return 14;
        if(d.compareTo("setubal") == 0)          return 15;
        if(d.compareTo("evora") == 0)            return 16;
        if(d.compareTo("beja") == 0)             return 17;
        if(d.compareTo("faro") == 0)             return 18;
        else return -1;
    }

    private static int switch_bin(String d){
        if(d.compareToIgnoreCase("nao") == 0) return 0;
        if(d.compareToIgnoreCase("sim") == 0) return 1;
        else return -1;
    }






    public static void main(String[] args) {

        String lineBuffer;
        int line = 1;

        try {
            //input file (.csv)
            BufferedReader input = new BufferedReader(new FileReader(args[0]));
            //output file (.pl)
            FileWriter output = new FileWriter(args[1]);

            //Fazer a declaração inicial dos predicados
            output.write("\n\n%                         ---Predicados---\n\n");
            output.write(":-dynamic cidade/" + CIDADE_SIZE + ".\n");
            output.write(":-dynamic distrito/2.\n");
            output.write(":-dynamic aresta/3.\n");

            output.write("\n\n%                           ---Cidades---\n\n");

            //A primeira linha é para ignorar
            lineBuffer = input.readLine();

            //Escrever cada uma das cidades
            while ((lineBuffer = input.readLine()) != null) {
                //Ler uma linha
                String[] tokens = lineBuffer.split(";");
                StringBuilder sb = new StringBuilder();

                //Para processar as linhas com inconsistências
                if (tokens.length != CIDADE_SIZE) {
                    int j = 0;
                    System.out.println("Linha incompleta: " + line + " (" + tokens.length + ")");
                    line++;
                    for (String s : tokens) {
                        System.out.println(j + ": " + tokens[j]);
                        j++;
                    }
                }

                int id = -1, dist = -1, is_capital = -1;
                float x = -1, y = -1;

                //Formatar o input para ficar com o aspeto correto
                for (int i = 0; i < tokens.length; i++) {
                    switch (i){
                        //Para o ID
                        case 0:{
                            //Começar um novo predicado cidade/8
                            sb.append("cidade(");
                            //Guardar o ID
                            id = Integer.parseInt(tokens[i]);
                            //Trocar espaços brancos por underscore
                            tokens[i] = tokens[i].replaceAll("\\s+", "_");
                            //Ignorar pontos e vírgulas
                            tokens[i] = tokens[i].replaceAll("[,.]", ".");
                            //Colocar tudo em lower case
                            tokens[i] = tokens[i].toLowerCase();
                            //Adicionar o parâmetro
                            sb.append(tokens[i]);
                            break;
                        }
                        //Para o nome da cidade
                        case 1:{
                            //Trocar espaços brancos por underscore
                            tokens[i] = tokens[i].replaceAll("\\s+", "_");
                            //Ignorar pontos e vírgulas
                            tokens[i] = tokens[i].replaceAll("[,.]", ".");
                            //Colocar tudo em lower case
                            tokens[i] = tokens[i].toLowerCase();
                            //Adicionar o parâmetro
                            sb.append(tokens[i]);
                            break;
                        }
                        //Para a latitude
                        case 2:{
                            //Trocar espaços brancos por underscore
                            tokens[i] = tokens[i].replaceAll("\\s+", "_");
                            //Ignorar pontos e vírgulas
                            tokens[i] = tokens[i].replaceAll("[,.]", ".");
                            //Colocar tudo em lower case
                            tokens[i] = tokens[i].toLowerCase();
                            //Adicionar a latitude
                            sb.append(tokens[i]);
                            //Guardar a latitude
                            x = Float.parseFloat(tokens[i]);
                            break;
                        }
                        //Para a longitude
                        case 3:{
                            //Trocar espaços brancos por underscore
                            tokens[i] = tokens[i].replaceAll("\\s+", "_");
                            //Ignorar pontos e vírgulas
                            tokens[i] = tokens[i].replaceAll("[,.]", ".");
                            //Colocar tudo em lower case
                            tokens[i] = tokens[i].toLowerCase();
                            //Adicionar a longitude
                            sb.append(tokens[i]);
                            //Guardar a longitude
                            y = Float.parseFloat(tokens[i]);
                            break;
                        }
                        //Para o distrito
                        case 4:{
                            //Trocar espaços brancos por underscore
                            tokens[i] = tokens[i].replaceAll("\\s+", "_");
                            //Colocar tudo em lower case
                            tokens[i] = tokens[i].toLowerCase();
                            //Guardar o distrito
                            dist = switch_distrito(tokens[i]);
                            //Append do distrito
                            sb.append(dist);

                            //Adicionar ao map dos distritos
                            if(distritos.containsKey(dist)){
                                List<Integer> aux = distritos.get(dist);
                                aux.add(id);
                                distritos.put(dist, aux);
                            }
                            else{
                                List<Integer> aux = new ArrayList<>();
                                aux.add(id);
                                distritos.put(dist, aux);
                            }
                            break;
                        }
                        //Para o admin/primary/minor
                        case 5:{
                            //Trocar espaços brancos por underscore
                            tokens[i] = tokens[i].replaceAll("\\s+", "");
                            //Colocar tudo em lower case
                            tokens[i] = tokens[i].toLowerCase();
                            //Trocar a etiqueta por um número e Adicionar ao map das capitais distritais se for o caso
                            if(tokens[i].compareTo("minor") == 0){
                                sb.append(3);
                                cidades.put(id, new Cidade(id, dist, x, y, 0));
                            }
                            if(tokens[i].compareTo("admin") == 0){
                                sb.append(2);
                                capitais_distritais.put(dist, new Cidade(id, dist, x, y, 1));
                                cidades.put(id, new Cidade(id, dist, x, y, 1));
                            }
                            if(tokens[i].compareTo("primary") == 0){
                                sb.append(1);
                                capitais_distritais.put(dist, new Cidade(id, dist, x, y, 1));
                                cidades.put(id, new Cidade(id, dist, x, y, 1));
                            }

                            break;
                        }
                        //Para as cenas opcionais
                        default:{
                            //Trocar espaços brancos por underscore
                            tokens[i] = tokens[i].replaceAll("\\s+", "");
                            //Colocar tudo em lower case
                            tokens[i] = tokens[i].toLowerCase();
                            //Trocar o sim/não por um número
                            sb.append(switch_bin(tokens[i]));
                            break;
                        }
                    }
                    if(i != CIDADE_SIZE-1){
                        //Para meter as vírgulas
                        sb.append(",");
                    }
                    else{
                        //Acabar uma linha
                        sb.append(").\n");
                    }

                }
                output.write(sb.toString());
            }

            //Escrever os distritos
            output.write("\n\n%                         ---Distritos---\n\n");
            write_distritos(output);

            //Escrever as arestas
            output.write("\n\n%                          ---Grafo---\n\n");

            //Guardar arestas em memória do programa
            write_arestas_dists();

            //Se não quisermos o grafo simples
            if(args.length == 3 && args[2].compareToIgnoreCase("complex") == 0){
                //Escrever as arestas entre capitais e as cidades do distrito
                write_arestas_cids_dist();
                //Escrever as arestas aleatórias
                write_rand_arestas(1, 3);
            }

            //Guardar as arestas em ficheiro
            write_grafo(output);

            //Fazer flush e fechar os readers/writers
            output.flush();
            output.close();
            input.close();
        }
        catch (IOException e) {
            e.printStackTrace();
        }
    }
}
