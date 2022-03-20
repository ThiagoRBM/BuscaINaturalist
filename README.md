# BuscaINaturalist

Script que, com base em uma lista de nomes de taxa (qualquer nível, espécie, gênero, família, etc) e uma lista de nomes de localidades (países, cidades e estados funcionam bem aparentemente), retorna uma tabela com as observações registradas no INaturalist e informações como data, coordenadas, descrição quando o autor coloca, fenologia e etc, usando a API do site.

A tabela "NomesInat.xlsx" nesse repositório serve como um exemplo simples de uso.

Existem 3 funções no script:

1. A primeira função recebe um vetor de nomes de taxa e busca no site do Inaturalist qual o código de cada taxa listado. No site do INat, cada taxa (em todos os nívels taxonômicos) recebe um código identificador único e esse código que é usado para buscar as informações no site. É gerada uma tabela com o nome buscado, o código do nome, o nível taxonômico e o número de observações daquele taxon.
2. A segunda função recebe um vetor de localidades e busca os respectivos códigos. Assim como acontece com taxa, localidades também recebem códigos únicos. É gerada uma tabela com o nome buscado e o respectivo código.
3. A terceira função recebe um vetor de códigos de taxa e um vetor de códigos de localidades e busca informações no site. Uma tabela é gerada, com as seguintes colunas: 

**quality_grade**: qualidade da observação, uma vez que o site classifica as mesmas em vários níveis (e.g., "casual", "pesquisa" e etc).  
**quality_grade**: data da observação.  
**id**: código da observação (assim como acontece com taxa e localidade, cada observação tem um código).  
**uuid**: outro código único para cada observação, em outro formato.  
**identifications_most_agree**: se a comunidade do site concorda com a identificação ou não. Caso só existe uma identificação na observação ou caso exista discordância na identidade, o valor será FALSE. Essa coluna é melhor ser usada em conjunto com **quality_grade**.  
**species_guess**: espécie que o autor da observação sugeriu. Pode ter valores bem variáveis e não necessariamente nome cientifico. Identificações como "planta", "pássaro", aparecerão nesse campo.  
**tags**: observações do autor, também variadas, geralmente (mas nem sempre) relacionadas ao ambiente que o organismo foi visto (por exemplo, bioma, se perto de um riacho, etc).  
**created_at**: quando a observação foi criada.  
**description**: outro campo variável, aberto a qualquer coisa que o criador da observação tenha achado relevante escrever. Na maioria das vezes está em branco.
**uri**: url da observação. Copiando e colando o valor em um navegador, é possível ir direto para a observação.  
**community_taxon_id**: o taxon ao qual a comunidade acha que o organismo pertence. Em formato de código.  
**long** e **lat**: coordenadas da observação.  
**taxon**: taxon da observação. Pode ser qualquer nível taxonômico.  
**pais** , **estado** e **cidade**: informações sobre o local da observação. Em formato de código.  
**hospedeira.nome**: taxon espécie hospedeira, caso o autor tenha fornecido. Informação pode ser útil ao se procurar dados de abelhas ou plantas parasitas, por exemplo.  
**hospedeira.cod**: taxon espécie hospedeira, em formato de código.  
**flores** , **frutos** e **botao**: informações da fenologia na planta, caso a comunidade ou o autor tenham indicado.  
