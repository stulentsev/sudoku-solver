use std::env::args;
use std::io;
use std::time::Instant;

macro_rules! parse_input {
    ($x:expr, $t:ident) => ($x.trim().parse::<$t>().unwrap())
}

fn main() {
    let args: Vec<String> = args().skip(1).collect();
    let size = parse_input!(args.first().unwrap_or(&"9".to_string()), usize);
    let mut lines = Vec::with_capacity(size);
    for _ in 0..size {
        let mut input_line = String::new();
        io::stdin().read_line(&mut input_line).unwrap();
        let row = input_line.trim_matches('\n').to_string();
        lines.push(row);
    }

    let start = Instant::now();
    let mut solver = SudokuSolver::new(size);
    let k =solver.seed(lines);

    if solver.search(k) {
        solver.print_solution(&solver.solution);
        eprintln!("elapsed: {:?}", start.elapsed());
    } else {
        println!("solution not found");
    }
}

struct DlxNode {
    id: usize,
    l: usize,
    r: usize,
    u: usize,
    d: usize,

    c: usize, // column
    row_id: usize,
    size: usize,
}

impl DlxNode {
    fn new(node_id: usize, col_id: usize) -> Self {
        DlxNode {
            id: node_id,
            l: node_id,
            r: node_id,
            u: node_id,
            d: node_id,

            c: col_id,
            row_id: 0,
            size: 0,
        }
    }

    fn row_cell(node_id: usize, col_id: usize, row_id: usize) -> Self {
        DlxNode {
            id: node_id,
            l: node_id,
            r: node_id,
            u: node_id,
            d: node_id,

            c: col_id,
            row_id,
            size: 0,
        }
    }
}

struct SudokuSolver {
    size: usize,
    arena: Vec<DlxNode>,
    solution: Vec<usize>,
}

const HEADER_CEL: usize = 0;
const HEADER_ROW: usize = 1;
const HEADER_COL: usize = 2;
const HEADER_BLK: usize = 3;

struct ArenaBuilder {
    arena: Vec<DlxNode>,
}

impl ArenaBuilder {
    fn new(capacity: usize) -> Self {
        let mut arena = Vec::with_capacity(capacity);
        arena.push(DlxNode::new(0, 0));
        Self { arena }
    }

    fn peek_id(&self) -> usize {
        self.arena.len()
    }

    fn append_left(&mut self, node_id: usize, mut new_node: DlxNode) {
        let source = node_id;
        new_node.l = self.arena[source].l;
        new_node.r = node_id;

        let source_left = self.arena[source].l;
        self.arena[source_left].r = new_node.id;

        self.arena[source].l = new_node.id;

        self.arena.push(new_node);
    }

    fn append_up(&mut self, node_id: usize, mut new_node: DlxNode) {
        let source = node_id;
        new_node.c = self.arena[source].c;

        new_node.u = self.arena[source].u;
        new_node.d = node_id;

        let source_up = self.arena[source].u;
        self.arena[source_up].d = new_node.id;

        self.arena[source].u = new_node.id;
        self.arena[source].size += 1;
        self.arena.push(new_node)
    }

    fn append_row(&mut self, row: Vec<DlxNode>) {
        for node in row {
            self.append_up(node.c, node);
        }
    }
}

impl SudokuSolver {
    pub fn new(size: usize) -> Self {
        let sqrt_size = size.isqrt();
        let num_constraints = 4; // four constraints: pos (row-col), row, column, sector/block
        let column_count = size * size // grid size
            * num_constraints;

        let row_count = size * size // every possible position on the board
            * size; // holding every possible symbol

        let cell_count = row_count * num_constraints; // node per constraint

        let arena_size = 1 + // root node
            column_count + cell_count;

        let solution_size = size * size;

        let mut builder = ArenaBuilder::new(arena_size);

        for _ in 0..num_constraints * size * size {
            let node_id = builder.peek_id();
            let col_id = builder.peek_id();
            let header = DlxNode::new(node_id, col_id);
            builder.append_left(0, header);
        }

        for num in 0..size {
            for row in 0..size {
                for col in 0..size {
                    // need to create 4 nodes now
                    let mut nodes = Vec::with_capacity(4);
                    let base_id = builder.peek_id();
                    let row_id = pack_row_id(size, row, col, num);
                    let blk = {
                        let r1 = row / sqrt_size;
                        let c1 = col / sqrt_size;
                        r1 * sqrt_size + c1
                    };

                    nodes.push(DlxNode::row_cell(
                        base_id,
                        1 + HEADER_CEL * size * size + row * size + col,
                        row_id,
                    ));
                    nodes.push(DlxNode::row_cell(
                        base_id + 1,
                        1 + HEADER_ROW * size * size + row * size + num,
                        row_id,
                    ));
                    nodes.push(DlxNode::row_cell(
                        base_id + 2,
                        1 + HEADER_COL * size * size + col * size + num,
                        row_id,
                    ));
                    nodes.push(DlxNode::row_cell(
                        base_id + 3,
                        1 + HEADER_BLK * size * size + blk * size + num,
                        row_id,
                    ));

                    for i in 0..nodes.len() {
                        let j = (i + 1) % nodes.len();
                        nodes[i].r = nodes[j].id;
                        nodes[j].l = nodes[i].id;
                    }

                    builder.append_row(nodes);
                }
            }
        }

        Self {
            arena: builder.arena,
            solution: vec![0; solution_size],
            size,
        }
    }

    fn seed(&mut self, lines: Vec<String>) -> usize {
        let mut k = 0;
        let sqrt_size = self.size.isqrt();
        for (line_idx, line) in lines.iter().enumerate() {
            for (char_idx, char) in line.chars().enumerate() {
                if char == '.' || char == ' ' {
                    continue;
                }
                k += 1;
                let num = self.encode_symbol(char);
                let blk = {
                    let r1 = line_idx / sqrt_size;
                    let c1 = char_idx / sqrt_size;
                    r1 * sqrt_size + c1
                };

                self.cover(1 + HEADER_CEL * self.size * self.size + line_idx  * self.size + char_idx);
                self.cover(1 + HEADER_ROW * self.size * self.size + line_idx  * self.size + num);
                self.cover(1 + HEADER_COL * self.size * self.size + char_idx * self.size + num);
                self.cover(1 + HEADER_BLK * self.size * self.size + blk  * self.size + num);

                let row_id = pack_row_id(self.size, line_idx, char_idx, num);
                self.solution.push(row_id);
            }
        }
        k
    }

    pub fn cover(&mut self, col_id: usize) {
        // unlink from the control row
        let l = self.arena[col_id].l;
        let r = self.arena[col_id].r;
        self.arena[l].r = r;
        self.arena[r].l = l;

        let mut d = self.arena[col_id].d;

        loop {
            if d == col_id {
                break;
            }

            let mut r = self.arena[d].r;

            loop {
                if r == d {
                    break;
                }

                let r_up = self.arena[r].u;
                let r_down = self.arena[r].d;
                let r_col = self.arena[r].c;

                self.arena[r_up].d = self.arena[r].d;
                self.arena[r_down].u = self.arena[r].u;
                self.arena[r_col].size -= 1;

                r = self.arena[r].r;
            }

            d = self.arena[d].d;
        }
    }

    pub fn uncover(&mut self, col_id: usize) {
        // up, then left
        //  re-link vertically
        let mut u = self.arena[col_id].u;

        loop {
            if u == col_id {
                break;
            }

            let mut l = self.arena[u].l;

            loop {
                if l == u {
                    break;
                }

                let l_up = self.arena[l].u;
                let l_down = self.arena[l].d;
                let l_col = self.arena[l].c;

                // re-link vertically
                self.arena[l_up].d = l;
                self.arena[l_down].u = l;
                self.arena[l_col].size += 1;

                l = self.arena[l].l;
            }

            u = self.arena[u].u;
        }

        // relink to control row
        let l = self.arena[col_id].l;
        let r = self.arena[col_id].r;
        self.arena[l].r = col_id;
        self.arena[r].l = col_id;
    }

    pub fn search(&mut self, k: usize) -> bool {
        if self.arena[0].r == 0 { // control row empty
            return true;
        }
        
        let col_id = self.pick_column();
        self.cover(col_id);

        let mut row = self.arena[col_id].d;

        loop {
            if row == col_id {
                break;
            }

            // choose row
            self.solution[k] = self.arena[row].row_id;
            
            // cover columns
            let mut r = self.arena[row].r;
            loop {
                if r == row { break }

                self.cover(self.arena[r].c);

                r = self.arena[r].r;
            }
            
            
            let ok = self.search(k + 1);
            if ok {
                return true;
            }
            
            // uncover columns
            let mut l = self.arena[row].l;
            loop {
                if l == row { break }

                self.uncover(self.arena[l].c);

                l = self.arena[l].l;
            }
            
            row = self.arena[row].d;
        }

        self.uncover(col_id);

        false
    }

    // go through the control row and select a column with minimal size
    fn pick_column(&self) -> usize {
        let mut min_size = usize::MAX;
        let mut best = 0usize;

        let mut c = self.arena[0].r;
        loop {
            if c == 0 { // back to root
                break;
            }
            let col = &self.arena[c];
            if col.size < 2 {
                return c
            }

            if col.size < min_size {
                min_size = col.size;
                best = c;
            }
            c = self.arena[c].r;
        }
        best
    }

    fn encode_symbol(&self, char: char) -> usize {
        match self.size {
            25 => (char as u8 - b'A') as usize,
            9 => (char as u8 - b'1') as usize,
            s => panic!("unsupported puzzle size: {}", s)
        }
    }

    fn decode_symbol(&self, v: usize) -> char {
        match self.size {
            25 => (b'A' + v as u8) as char,
            9 => (b'1' + v as u8) as char,
            s => panic!("unsupported puzzle size: {}", s)
        }
    }

    fn print_solution(&self, solution: &[usize]) {
        let mut grid = vec![vec!['.'; self.size]; self.size];

        for row_id in solution {
            let (r, c, v) = self.unpack_row_id(*row_id);
            let char = self.decode_symbol(v);
            grid[r][c] = char;
        }

        for row in grid.iter() {
            for char in row.iter() {
                print!("{}", char);
            }
            println!();
        }
    }


    // returns (r, c, v)
    fn unpack_row_id(&self, id: usize) -> (usize, usize, usize) {
        let s = self.size;
        (id / s / s, id / s % s, id % s)
    }
}

fn pack_row_id(s: usize, r: usize, c: usize, v: usize) -> usize {
    r * s * s + c * s + v
}
