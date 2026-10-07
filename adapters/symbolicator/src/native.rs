use std::fs::File;
use std::io::BufWriter;
use std::path::Path;

use symbolic::common::ByteView;
use symbolic::debuginfo::{Archive, Object};
use symbolic::demangle::{Demangle, DemangleOptions};
use symbolic::symcache::{SymCache, SymCacheConverter};
use tonic::Status;

use crate::service::unreadable;
use crate::wire::{Indexed, Resolved, SourceFrame};

pub fn inspect(path: &Path, cache: &Path) -> Result<Vec<Indexed>, Status> {
    let view = ByteView::open(path).map_err(|failure| unreadable(path, failure))?;
    let archive = Archive::parse(&view).map_err(|failure| unreadable(path, failure))?;
    let mut entries = Vec::new();
    for object in archive.objects() {
        let object = object.map_err(|failure| unreadable(path, failure))?;
        if let Some(entry) = index(&object, cache).map_err(|failure| unreadable(path, failure))? {
            entries.push(entry);
        }
    }
    if entries.is_empty() {
        return Err(Status::invalid_argument(format!(
            "{} holds no object with an identifier and symbols",
            path.display()
        )));
    }
    Ok(entries)
}

fn index(object: &Object<'_>, cache: &Path) -> Result<Option<Indexed>, Box<dyn std::error::Error>> {
    let Some(code_id) = object.code_id() else {
        return Ok(None);
    };
    if !object.has_debug_info() && !object.has_symbols() {
        return Ok(None);
    }
    let identifier = code_id.as_str().to_ascii_lowercase();
    let target = cache.join(format!("{identifier}.symcache"));
    let mut converter = SymCacheConverter::new();
    converter.process_object(object)?;
    let mut writer = BufWriter::new(File::create(&target)?);
    converter.serialize(&mut writer)?;
    Ok(Some(Indexed {
        identifier,
        path: target.to_string_lossy().into_owned(),
    }))
}

pub fn lookup(path: &Path, addresses: &[u64]) -> Result<Vec<Resolved>, Status> {
    let view = ByteView::open(path).map_err(|failure| unreadable(path, failure))?;
    let cache = SymCache::parse(&view).map_err(|failure| unreadable(path, failure))?;
    Ok(addresses
        .iter()
        .map(|address| Resolved {
            frames: cache
                .lookup(*address)
                .map(|location| SourceFrame {
                    module: String::new(),
                    function: location
                        .function()
                        .name_for_demangling()
                        .try_demangle(DemangleOptions::name_only())
                        .into_owned(),
                    file: location
                        .file()
                        .map(|file| file.full_path())
                        .unwrap_or_default(),
                    line: location.line(),
                    column: 0,
                })
                .collect(),
        })
        .collect())
}
