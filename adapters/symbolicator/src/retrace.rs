use std::path::Path;

use proguard::{ProguardMapper, ProguardMapping, StackFrame};
use tonic::Status;

use crate::service::unreadable;
use crate::wire::{Indexed, JvmFrame, Resolved, SourceFrame};

fn read(path: &Path) -> Result<Vec<u8>, Status> {
    std::fs::read(path).map_err(|failure| unreadable(path, failure))
}

pub fn inspect(path: &Path) -> Result<Vec<Indexed>, Status> {
    let bytes = read(path)?;
    if !ProguardMapping::new(&bytes).is_valid() {
        return Err(Status::invalid_argument(format!(
            "{} is not an R8 mapping",
            path.display()
        )));
    }
    Ok(vec![Indexed {
        identifier: String::new(),
        path: path.to_string_lossy().into_owned(),
    }])
}

pub fn remap(path: &Path, frames: &[JvmFrame]) -> Result<Vec<Resolved>, Status> {
    let bytes = read(path)?;
    let mapper = ProguardMapper::new(ProguardMapping::new(&bytes));
    Ok(frames
        .iter()
        .map(|frame| Resolved {
            frames: remapped(&mapper, frame),
        })
        .collect())
}

fn remapped(mapper: &ProguardMapper<'_>, frame: &JvmFrame) -> Vec<SourceFrame> {
    let line = usize::try_from(frame.line).unwrap_or_default();
    let obfuscated = if frame.file.is_empty() {
        StackFrame::new(&frame.class_name, &frame.method, line)
    } else {
        StackFrame::with_file(&frame.class_name, &frame.method, line, &frame.file)
    };
    let expanded: Vec<SourceFrame> = mapper
        .remap_frame(&obfuscated)
        .map(|original| SourceFrame {
            module: original.class().to_owned(),
            function: original.method().to_owned(),
            file: original.file().unwrap_or_default().to_owned(),
            line: original
                .line()
                .and_then(|line| u32::try_from(line).ok())
                .unwrap_or_default(),
            column: 0,
        })
        .collect();
    if !expanded.is_empty() {
        return expanded;
    }
    mapper
        .remap_method(&frame.class_name, &frame.method)
        .map(|(class, method)| SourceFrame {
            module: class.to_owned(),
            function: method.to_owned(),
            file: String::new(),
            line: frame.line,
            column: 0,
        })
        .into_iter()
        .collect()
}
