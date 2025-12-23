use std::env::args;
use std::fs::File;
use std::io;
use std::io::{BufRead, BufReader};

macro_rules! parse_input {
    ($x:expr, $t:ident) => ($x.trim().parse::<$t>().unwrap())
}

fn main() {
    let mut lines = Vec::with_capacity(25);
    for i in 0..25 as usize {
        let mut input_line = String::new();
        io::stdin().read_line(&mut input_line).unwrap();
        let row = input_line.trim_matches('\n').to_string();
        lines.push(row);
    }

    let mut solver = SudokuSolver::new();
    let k =solver.seed(lines);

    if solver.search(k as usize) {
        print_solution(&solver.solution);
    } else {
        println!("solution not found");
    }
}

fn pack_row_id(s: u16, r: u16, c: u16, v: u16) -> u16 {
    r * s * s + c * s + v
}

// returns (r, c, v)
fn unpack_row_id(s: u16, id: u16) -> (u16, u16, u16) {
    (id / s / s, id / s % s, id % s)
}

fn print_solution(solution: &[u16]) {
    let mut grid = [['.'; 25]; 25];

    for row_id in solution {
        let (r, c, v) = unpack_row_id(25, *row_id);
        let char = (b'A' + v as u8) as char;
        grid[r as usize][c as usize] = char;
    }

    for row in grid.iter() {
        for char in row.iter() {
            print!("{}", char);
        }
        println!();
    }
}

struct DlxNode {
    id: u16,
    l: u16,
    r: u16,
    u: u16,
    d: u16,

    c: u16, // column
    row_id: u16,
    size: u16,
}

impl DlxNode {
    fn new(node_id: u16, col_id: u16) -> Self {
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

    fn row_cell(node_id: u16, col_id: u16, row_id: u16) -> Self {
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
    arena: Vec<DlxNode>,
    solution: Vec<u16>,
}

const HEADER_CEL: u16 = 0;
const HEADER_ROW: u16 = 1;
const HEADER_COL: u16 = 2;
const HEADER_BLK: u16 = 3;

struct ArenaBuilder {
    arena: Vec<DlxNode>,
}

impl ArenaBuilder {
    fn new(capacity: usize) -> Self {
        let mut arena = Vec::with_capacity(capacity);
        arena.push(DlxNode::new(0, 0));
        Self { arena }
    }

    fn peek_id(&self) -> u16 {
        self.arena.len() as u16
    }

    fn append_left(&mut self, node_id: u16, mut new_node: DlxNode) {
        let source = node_id as usize;
        new_node.l = self.arena[source].l;
        new_node.r = node_id;

        let source_left = self.arena[source].l;
        self.arena[source_left as usize].r = new_node.id;

        self.arena[source].l = new_node.id;

        self.arena.push(new_node);
    }

    fn append_up(&mut self, node_id: u16, mut new_node: DlxNode) {
        let source = node_id as usize;
        new_node.c = self.arena[source].c;

        new_node.u = self.arena[source].u;
        new_node.d = node_id;

        let source_up = self.arena[source].u;
        self.arena[source_up as usize].d = new_node.id;

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
    pub fn new() -> Self {
        let size: u16 = 25;
        let num_constraints = 4; // four constraints: pos (row-col), row, column, sector/block
        let column_count = size * size // grid size
            * num_constraints;

        let row_count = size * size // every possible position on the board
            * 25; // holding every possible symbol

        let cell_count = row_count * num_constraints; // node per constraint

        let arena_size = 1 + // root node
            column_count + cell_count;

        let solution_size = size * size;

        let mut builder = ArenaBuilder::new(arena_size as usize);

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
                        let r1 = row / 5;
                        let c1 = col / 5;
                        r1 * 5 + c1
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
            solution: vec![0; solution_size as usize],
        }
    }

    fn seed(&mut self, lines: Vec<String>) -> u16 {
        let size = 25;
        let mut k = 0;
        for (line_idx, line) in lines.iter().enumerate() {
            for (char_idx, char) in line.chars().enumerate() {
                if char == '.' {
                    continue;
                }
                k += 1;
                let num = (char as u8 - b'A') as u16;
                let blk = {
                    let r1 = line_idx / 5;
                    let c1 = char_idx / 5;
                    r1 * 5 + c1
                };

                self.cover(1 + HEADER_CEL * size * size + line_idx as u16 * size + char_idx as u16);
                self.cover(1 + HEADER_ROW * size * size + line_idx as u16 * size + num);
                self.cover(1 + HEADER_COL * size * size + char_idx as u16 * size + num);
                self.cover(1 + HEADER_BLK * size * size + blk as u16 * size + num);

                let row_id = pack_row_id(size, line_idx as u16, char_idx as u16, num);
                self.solution.push(row_id);
            }
        }
        k
    }

    pub fn cover(&mut self, col_id: u16) {
        // unlink from the control row
        let l = self.arena[col_id as usize].l;
        let r = self.arena[col_id as usize].r;
        self.arena[l as usize].r = r;
        self.arena[r as usize].l = l;

        let mut d = self.arena[col_id as usize].d;

        loop {
            if d == col_id {
                break;
            }

            let mut r = self.arena[d as usize].r;

            loop {
                if r == d {
                    break;
                }

                let r_up = self.arena[r as usize].u;
                let r_down = self.arena[r as usize].d;
                let r_col = self.arena[r as usize].c;

                self.arena[r_up as usize].d = self.arena[r as usize].d;
                self.arena[r_down as usize].u = self.arena[r as usize].u;
                self.arena[r_col as usize].size -= 1;

                r = self.arena[r as usize].r;
            }

            d = self.arena[d as usize].d;
        }
    }

    pub fn uncover(&mut self, col_id: u16) {
        // up, then left
        //  re-link vertically
        let mut u = self.arena[col_id as usize].u;

        loop {
            if u == col_id {
                break;
            }

            let mut l = self.arena[u as usize].l;

            loop {
                if l == u {
                    break;
                }

                let l_up = self.arena[l as usize].u;
                let l_down = self.arena[l as usize].d;
                let l_col = self.arena[l as usize].c;

                // re-link vertically
                self.arena[l_up as usize].d = l;
                self.arena[l_down as usize].u = l;
                self.arena[l_col as usize].size += 1;

                l = self.arena[l as usize].l;
            }

            u = self.arena[u as usize].u;
        }

        // relink to control row
        let l = self.arena[col_id as usize].l;
        let r = self.arena[col_id as usize].r;
        self.arena[l as usize].r = col_id;
        self.arena[r as usize].l = col_id;
    }

    pub fn search(&mut self, k: usize) -> bool {
        if self.arena[0].r == 0 { // control row empty
            return true;
        }
        
        let col_id = self.pick_column();
        self.cover(col_id);

        let mut row = self.arena[col_id as usize].d;

        loop {
            if row == col_id {
                break;
            }

            // choose row
            self.solution[k] = self.arena[row as usize].row_id;
            
            // cover columns
            let mut r = self.arena[row as usize].r;
            loop {
                if r == row { break }

                self.cover(self.arena[r as usize].c);

                r = self.arena[r as usize].r;
            }
            
            
            let ok = self.search(k + 1);
            if ok {
                return true;
            }
            
            // uncover columns
            let mut l = self.arena[row as usize].l;
            loop {
                if l == row { break }

                self.uncover(self.arena[l as usize].c);

                l = self.arena[l as usize].l;
            }
            
            row = self.arena[row as usize].d;
        }

        self.uncover(col_id);

        false
    }

    // go through the control row and select a column with minimal size
    fn pick_column(&self) -> u16 {
        let mut min_size = u16::MAX;
        let mut best = 0u16;

        let mut c = self.arena[0].r;
        loop {
            if c == 0 { // back to root
                break;
            }
            let col = &self.arena[c as usize];
            if col.size < 2 {
                return c
            }

            if col.size < min_size {
                min_size = col.size;
                best = c;
            }
            c = self.arena[c as usize].r;
        }
        best
    }
}
