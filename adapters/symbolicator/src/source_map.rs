use std::path::Path;

use sourcemap::DecodedMap;
use tonic::Status;

use crate::service::unreadable;
use crate::wire::{Indexed, Resolved, SourceFrame, SourcePosition};

fn decode(path: &Path) -> Result<DecodedMap, Status> {
    let bytes = std::fs::read(path).map_err(|failure| unreadable(path, failure))?;
    DecodedMap::from_reader(bytes.as_slice()).map_err(|failure| unreadable(path, failure))
}

fn file_of(map: &DecodedMap) -> Option<&str> {
    match map {
        DecodedMap::Regular(regular) => regular.get_file(),
        DecodedMap::Index(index) => index.get_file(),
        DecodedMap::Hermes(hermes) => hermes.get_file(),
    }
}

pub fn inspect(path: &Path) -> Result<Vec<Indexed>, Status> {
    let map = decode(path)?;
    Ok(vec![Indexed {
        identifier: file_of(&map).unwrap_or_default().to_owned(),
        path: path.to_string_lossy().into_owned(),
    }])
}

pub fn map(path: &Path, positions: &[SourcePosition]) -> Result<Vec<Resolved>, Status> {
    let map = decode(path)?;
    Ok(positions
        .iter()
        .map(|position| Resolved {
            frames: located(&map, position).into_iter().collect(),
        })
        .collect())
}

fn located(map: &DecodedMap, position: &SourcePosition) -> Option<SourceFrame> {
    let line = position.line.checked_sub(1)?;
    let column = position.column.saturating_sub(1);
    let token = map.lookup_token(line, column)?;
    if token.get_dst_line() != line {
        return None;
    }
    Some(SourceFrame {
        module: String::new(),
        function: token.get_name().unwrap_or_default().to_owned(),
        file: token.get_source()?.to_owned(),
        line: token.get_src_line() + 1,
        column: token.get_src_col() + 1,
    })
}
